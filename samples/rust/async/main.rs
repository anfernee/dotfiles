use futures::executor::block_on;

struct Song {
}

async fn learn_song() -> Song {
    println!("learn song");
    Song{}
}

async fn sing_song(_song: Song) {
    println!("sing song");
}

fn main() {
    let song = block_on(learn_song());
    block_on(sing_song(song));
}