
struct Song {
}

async fn learn_song() -> Option<Song> {
    println!("learn song");
    Some(Song{})
}

async fn sing_song(_song: Song) {
    println!("sing song");
}

#[tokio::main]
async fn main() {
    let song = learn_song().await.unwrap();
    sing_song(song).await
}