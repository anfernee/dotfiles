// From Curst of Rust: Atomics and Memory Ordering
// https://www.youtube.com/watch?v=rMGWeSjctlY&t=2497s


// UnsafeCell gives you .get() for a raw pointer *mut T
// https://doc.rust-lang.org/std/cell/struct.UnsafeCell.html
use std::cell::UnsafeCell;

use std::sync::atomic::AtomicBool;
use std::sync::atomic::Ordering;

const LOCKED: bool = true;
const UNLOCKED: bool = false;

pub struct Mutex<T> {
    v: UnsafeCell<T>,
    locked: AtomicBool,
}

// Without the following line `spawn` will return the following error:
// `UnsafeCell<i32>` cannot be shared between threads safely
//
// unsafe?
// Sync?
// Send?
unsafe impl<T> Sync for Mutex<T> where T: Send {}

impl<T> Mutex<T> {
    pub fn new(t: T) -> Self {
        Self {
            locked: AtomicBool::new(UNLOCKED),
            v: UnsafeCell::new(t),
        }
    }

    // R?
    // Ordering?
    pub fn with_lock_bad<R>(&self, f: impl FnOnce(&mut T) -> R) -> R {
        while self.locked.load(Ordering::Relaxed) != UNLOCKED {}
        self.locked.store(LOCKED, Ordering::Relaxed);

        // unsafe {}?
        let ret = f(unsafe { &mut *self.v.get() });
        self.locked.store(UNLOCKED, Ordering::Relaxed);
        ret
    }

    pub fn with_lock<R>(&self, f: impl FnOnce(&mut T) -> R) -> R {
        // x86: CAS
        // ARM: LDREX STREX
        //      - compare_exchange is implemented with a loop of LDREX and STREX. STREX might fail.
        //      - compare_exchange_weak: Just LDREX and STREX
        while self.locked.compare_exchange(UNLOCKED, LOCKED, Ordering::Relaxed, Ordering::Relaxed).is_err() {
            // MESI protocol
            while self.locked.load(Ordering::Relaxed) == LOCKED {
                std::thread::yield_now();
            }
            std::thread::yield_now();
        }
        let ret = f(unsafe { &mut *self.v.get() });
        self.locked.store(UNLOCKED, Ordering::Relaxed);
        ret
    }
}

use std::thread::spawn;

fn main() {
    // leak?
    // lifetime?
    // _ ?
    let l :&'static _ = Box::leak(Box::new(Mutex::new(0)));

    // _?
    let handles: Vec<_> = (0..8).map(|_| {
        // move?
        spawn(move || {
            for _ in 0..100 {
                l.with_lock(|v| {
                    *v += 1;
                });
            }
        })
    }).collect();

    for handle in handles {
        handle.join().unwrap();
    }

    assert_eq!(l.with_lock(|v| *v), 8 * 100);
}
