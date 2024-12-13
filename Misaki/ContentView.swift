//
//  ContentView.swift
//  Misaki
//
//  Created by PETERS on R 6/12/11.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var tweets: [Tweet] = PreviewData.shared.sampleTweets
    @State private var messages: [Message] = PreviewData.shared.sampleMessages
    @State private var messageText: String = ""
    @State private var songTitle: String = "Sample Song"
    @State private var isPlaying: Bool = false
    @State private var songURL: URL? = URL(string: "https://example.com/sample.mp3")
    @State private var userProfile: Profile = Profile(name: "User", favoriteSongs: [], bookmarkedTweets: [])

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                tweets: $tweets,
                postTweet: { tweet in
                    tweets.append(Tweet(id: UUID().uuidString, content: tweet, author: "Anonymous"))
                },
                userProfile: $userProfile
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            ChatView(
                messages: $messages,
                messageText: $messageText,
                sendMessage: {
                    messages.append(Message(id: UUID().uuidString, sender: "You", text: messageText))
                    messageText = ""
                }
            )
            .tabItem {
                Label("Chat", systemImage: "message.fill")
            }
            .tag(1)

            MusicView(
                songTitle: $songTitle,
                isPlaying: $isPlaying,
                songURL: songURL,
                togglePlayPause: {
                    isPlaying.toggle()
                    if isPlaying {
                        userProfile.favoriteSongs.append(songTitle)
                    }
                },
                profile: $userProfile
            )
            .tabItem {
                Label("Music", systemImage: "music.note")
            }
            .tag(2)
        }
        .accentColor(.blue)
        .onAppear {
            UITabBar.appearance().backgroundColor = UIColor.systemGray6
            UITabBar.appearance().unselectedItemTintColor = UIColor.gray
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// HomeView with Twitter functionality
struct HomeView: View {
    @Binding var tweets: [Tweet]
    var postTweet: (String) -> Void
    @State private var newTweet: String = ""
    @Binding var userProfile: Profile

    var body: some View {
        NavigationView {
            VStack {
                TextField("What's happening?", text: $newTweet)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    if !newTweet.isEmpty {
                        postTweet(newTweet)
                        newTweet = ""
                    }
                }) {
                    Text("Tweet")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                List($tweets) { $tweet in // Use $tweets to bind tweet
                    VStack(alignment: .leading) {
                        Text(tweet.author)
                            .font(.headline)
                        Text(parseHashtags(tweet.content))
                            .font(.body)
                            .foregroundColor(.gray)
                        HStack {
                            // Like Button
                            Button(action: {
                                tweet.likeTweet()
                            }) {
                                Image(systemName: tweet.isLiked ? "heart.fill" : "heart")
                                    .foregroundColor(tweet.isLiked ? .red : .gray)
                            }
                            .padding(.trailing)

                            // Comment Button
                            Button(action: {
                                tweet.showComments.toggle()
                            }) {
                                Image(systemName: "bubble.right")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing)

                            // Retweet Button
                            Button(action: {
                                tweet.retweet()
                            }) {
                                Image(systemName: "arrow.2.squarepath")
                                    .foregroundColor(.green)
                            }
                            .padding(.trailing)

                            // Share Button
                            Button(action: {
                                tweet.shareTweet()
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.blue)
                            }

                            // Dislike Button
                            Button(action: {
                                tweet.dislikeTweet()
                            }) {
                                Image(systemName: "hand.thumbsdown.fill")
                                    .foregroundColor(tweet.isDisliked ? .red : .gray)
                            }
                            .padding(.leading)
                        }
                        if tweet.showComments {
                            VStack {
                                ForEach(tweet.comments, id: \.id) { comment in
                                    Text(comment.text)
                                        .font(.subheadline)
                                        .padding(.leading)
                                }
                                HStack {
                                    TextField("Add a comment", text: $tweet.newComment)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .padding(.horizontal)

                                    Button(action: {
                                        tweet.addComment(tweet.newComment)
                                    }) {
                                        Image(systemName: "paperplane.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                    .padding(.vertical, 5)
                    .onTapGesture {
                        tweet.showComments.toggle()
                    }
                }
            }
            .navigationTitle("Home")
        }
    }

    private func parseHashtags(_ text: String) -> AttributedString {
        var attributedText = AttributedString(text)
        let regex = try! NSRegularExpression(pattern: "#(\\w+)")
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in matches {
            let hashtag = (text as NSString).substring(with: match.range)
            if let range = Range(match.range, in: text) {
                var hashtagAttributedString = AttributedString("#\(hashtag)")
                hashtagAttributedString.foregroundColor = .blue
                attributedText.replaceSubrange(Range(range, in: attributedText)!, with: hashtagAttributedString)
            }
        }
        return attributedText
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(
            tweets: .constant(PreviewData.shared.sampleTweets),
            postTweet: { _ in },
            userProfile: .constant(Profile(name: "User", favoriteSongs: [], bookmarkedTweets: []))
        )
    }
}

// Tweet Model with new functionality
struct Tweet: Identifiable {
    var id: String
    var content: String
    var author: String
    var isLiked: Bool = false
    var isDisliked: Bool = false
    var comments: [Comment] = []
    var newComment: String = ""
    var showComments: Bool = false

    mutating func likeTweet() {
        self.isLiked.toggle()
    }

    mutating func dislikeTweet() {
        self.isDisliked.toggle()
    }

    mutating func retweet() {
        // Add logic to handle retweet (e.g., increment retweet count, share to followers)
    }

    mutating func shareTweet() {
        // Share the tweet (this could open a sharing sheet or log the action)
    }

    mutating func addComment(_ commentText: String) {
        guard !commentText.isEmpty else { return }
        let newComment = Comment(id: UUID().uuidString, text: commentText)
        self.comments.append(newComment)
        self.newComment = ""
    }
}

struct Comment: Identifiable {
    var id: String
    var text: String
}

// Profile Model
struct Profile {
    var name: String
    var favoriteSongs: [String]
    var bookmarkedTweets: [Tweet]
}

// Message Model for ChatView
struct Message: Identifiable {
    var id: String
    var sender: String
    var text: String
}

// ChatView
struct ChatView: View {
    @Binding var messages: [Message]
    @Binding var messageText: String
    var sendMessage: () -> Void

    var body: some View {
        NavigationView {
            VStack {
                List(messages) { message in
                    VStack(alignment: .leading) {
                        Text(message.sender)
                            .font(.headline)
                        Text(message.text)
                            .font(.body)
                    }
                }

                HStack {
                    TextField("Type a message", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            }
            .navigationTitle("Chat")
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(
            messages: .constant(PreviewData.shared.sampleMessages),
            messageText: .constant(""),
            sendMessage: {}
        )
    }
}

// MusicView for Music Functionality
struct MusicView: View {
    @Binding var songTitle: String
    @Binding var isPlaying: Bool
    var songURL: URL?
    var togglePlayPause: () -> Void
    @Binding var profile: Profile

    var body: some View {
        VStack {
            Text(songTitle)
                .font(.headline)

            Button(action: togglePlayPause) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
            }

            if let url = songURL {
                Text("Playing from: \(url.absoluteString)")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .navigationTitle("Music")
    }
}

struct MusicView_Previews: PreviewProvider {
    static var previews: some View {
        MusicView(
            songTitle: .constant("Sample Song"),
            isPlaying: .constant(false),
            songURL: URL(string: "https://example.com/sample.mp3"),
            togglePlayPause: {},
            profile: .constant(Profile(name: "User", favoriteSongs: [], bookmarkedTweets: []))
        )
    }
}

// Preview Data
class PreviewData {
    static let shared = PreviewData()

    let sampleTweets = [
        Tweet(id: "1", content: "Hello, world! #firstTweet", author: "Alice"),
        Tweet(id: "2", content: "SwiftUI is amazing! #swift #ios", author: "Bob")
    ]

    let sampleMessages = [
        Message(id: "1", sender: "Alice", text: "Hi!"),
        Message(id: "2", sender: "Bob", text: "Hello, Alice!")
    ]
}

