use serde::Deserialize;
use serde_json;

#[derive(Deserialize, Debug)]
struct Beer {
    pub brand: String,
    pub year: u32,
}

fn main() {
    let body = String::from(r#"{
    "brand": "bluemoon",
    "year": 2020
}"#);

    let result: Beer = serde_json::from_str(&body).unwrap();
    println!("{:#?}", result);
}