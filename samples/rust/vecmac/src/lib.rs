macro_rules! avec {
    ($arg1:ty, $arg2:expr) => {};
    ($arg1:ty => $arg2:expr; $arg3:path) => {};
}


pub fn try_vec() {
    let x = 1;
    avec!(x, x + 1);
    print!("{}", x);
}

#[test]
fn it_works() {
    try_vec();
    assert_eq!(2 + 2, 4);
}
