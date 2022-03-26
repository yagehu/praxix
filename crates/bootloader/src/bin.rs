#![no_std]
#![no_main]

use core::{arch::global_asm, panic::PanicInfo};

global_asm!(include_str!("asm/stage_1.S"));

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {
    }
}
