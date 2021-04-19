// #![warn(missing_debug_implementations, rust_2018_idioms)]

#[derive(Debug)]
pub struct StrSplit<'a, 'b> {
    remainder: &'a str,
    delimiter: &'b str,
}

/*
Make it generic.. 

pub struct StrSplit<'a, D> {
    remainder: &'a str,
    delimiter: D,
}

impl<'a, D> Iterator for StrSplit<'a, D>
where
    D: Delimiter
*/

pub trait Delimiter {
    // find_next find delimiter's start and end
    fn find_next(&self, s: &str) -> Option<(usize, usize)>;
}

impl Delimiter for &str {
    fn find_next(&self, s: &str) -> Option<(usize, usize)> {
        s.find(self).map(|start| (start, start + self.len()))
    }
}

// Differece of str and String
// str -> [char], slice of chars, it doesn't know how long
// &str -> &[char], could be anywhere, stack or heap.
// String -> Vec<char>, heap allocated, dynamically expand and shrink.vec!

// String ==> &str (cheap -- AsRef)
// &str ===> String (expensive -- Clone, memcpy)



// [E0312] lifetime of reference outlieves lifetime of borrowed content ...
// Self has some lifetime 'a, so remaider has the same lifetime, but haystack's lifetime
// is not clear. Same to delimiter.
/*
impl StrSplit<'_> {
    pub fn new(haystack: &str, delimiter: &str) -> Self {
        Self {
            remainder: haystack,
            delimiter,
        }
    }
}
*/

// Give me haystack and delimiter of whatever lifetime 'a, I'll
// give you back StrSplit with the same lifetime.
impl<'a, 'b> StrSplit<'a, 'b> {
    pub fn new(haystack: &'a str, delimiter: &'b str) -> Self {
        Self {
            remainder: haystack,
            delimiter,
        }
    }
}

impl<'a, 'b> Iterator for StrSplit<'a, 'b> {
    type Item = &'a str;

    fn next(&mut self) -> Option<Self::Item> {
        // if let Some(ref mut remainer) = self.remainder
        // let remainder = self.remainder.as_mut()?

        // as_mut() is an Option<T> function.

        if let Some(next_delim) = self.remainder.find(self.delimiter) {
            let ret = &self.remainder[..next_delim];
            self.remainder = &self.remainder[(next_delim + self.delimiter.len())..];
            Some(ret)
        } else if self.remainder.is_empty() {
            None
        } else {
            let rest = self.remainder;
            self.remainder = "";
            Some(rest)
        }
    }
}

pub fn until_char(s: &str, c: char) -> &'_ str {
    // Error: cannot return value referencing temporary value, if impl<'a>, not impl<'a, 'b>
    StrSplit::new(s, &format!("{}", c)).next().expect("StrSplit failed")
}

#[test]
fn until_char_test() {
    let ret = until_char("hello, world", 'o');
    assert_eq!(ret, "hell");
}

#[test]
fn it_works() {
    let haystack = "a b c";
    let letters = StrSplit::new(haystack, " ");

    // ERROR: requires trait PartialEq. WHY?..
    // assert_eq!(letters, vec!["a", "b", "c"].into_iter());

    assert!(letters.eq(vec!["a", "b", "c"].into_iter()))
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
