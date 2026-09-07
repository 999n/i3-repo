#!/usr/bin/env python3
# float-layout-watcher.py
# 1. Re-runs active layout on floating focus change (debounced).
# 2. Records size after mouse drag-resize (window::move event with size change).

import i3ipc, subprocess, os, threading, time

STATE  = "/tmp/float-active-layout"
GRACE  = 0.6
LOCK   = "/tmp/float-layout-running"
MANUAL = "/tmp/float-manual-sizes"

open(MANUAL, 'a').close()

i3 = i3ipc.Connection()
_timer = None
_prev_sizes = {}  # con_id -> (w, h) before move/resize

def run_layout():
    if os.path.exists(LOCK):
        if time.time() - os.path.getmtime(LOCK) < 10:
            return
        os.remove(LOCK)
    if not os.path.exists(STATE):
        return
    with open(STATE) as f:
        layout = f.read().strip()
    if not layout:
        return
    open(LOCK, 'w').close()
    try:
        subprocess.run(['/bin/bash', layout], timeout=5)
    finally:
        try:
            os.remove(LOCK)
        except FileNotFoundError:
            pass

def record_size(con_id, w, h):
    try:
        with open(MANUAL) as f:
            lines = [l for l in f if not l.startswith(f"{con_id} ")]
    except FileNotFoundError:
        lines = []
    lines.append(f"{con_id} {w} {h}\n")
    with open(MANUAL, 'w') as f:
        f.writelines(lines)

PINNED = "/tmp/float-pinned-ids"

FOCUS_LOCK = "/tmp/float-focus-lock"

def on_focus(i3, event):
    global _timer
    con = event.container
    if con.floating not in ('user_on', 'auto_on'):
        return
    if not os.path.exists(STATE):
        return
    if os.path.exists(LOCK):
        return
    if os.path.exists(FOCUS_LOCK):
        return
    # Don't re-run layout if focused window is pinned
    try:
        pinned = open(PINNED).read().split() if os.path.exists(PINNED) else []
        if str(con.id) in pinned:
            return
    except Exception:
        pass
    if _timer:
        _timer.cancel()
    _timer = threading.Timer(GRACE, run_layout)
    _timer.daemon = True
    _timer.start()

def on_move(i3, event):
    """Detect mouse drag-resizes: window::move fires on both move and resize."""
    if os.path.exists(LOCK):
        return
    con = event.container
    if con.floating not in ('user_on', 'auto_on'):
        return
    con_id = con.id
    w, h = con.rect.width, con.rect.height
    prev = _prev_sizes.get(con_id)
    _prev_sizes[con_id] = (w, h)
    # Only record if size actually changed (drag-resize, not just move)
    if prev is not None and (w != prev[0] or h != prev[1]):
        record_size(con_id, w, h)

def on_close(i3, event):
    con = event.container
    con_id = con.id
    _prev_sizes.pop(con_id, None)
    if con.floating in ('user_on', 'auto_on'):
        cls   = (con.window_class or '').strip()
        title = (con.name or '').strip()
        if cls:
            subprocess.Popen(['/bin/bash', os.path.expanduser('~/bin/float-graveyard.sh'),
                              '--record', cls, title])
    try:
        with open(MANUAL) as f:
            lines = [l for l in f if not l.startswith(f"{con_id} ")]
        with open(MANUAL, 'w') as f:
            f.writelines(lines)
    except FileNotFoundError:
        pass

i3.on('window::focus', on_focus)
i3.on('window::move', on_move)
i3.on('window::close', on_close)
i3.main()
