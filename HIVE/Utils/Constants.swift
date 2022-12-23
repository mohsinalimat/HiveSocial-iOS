//
//  Constants.swift
//  HIVEcopy
//
//  Created by Kassy Pop on 7/30/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

// MARK: - Root References
let STORAGE_REF = Storage.storage().reference()
let FDB_REF = Firestore.firestore()

// MARK: - Storage References
let STORAGE_PROFILE_IMAGES_REF = STORAGE_REF.child("profile_images")
let STORAGE_MESSAGE_IMAGES_REF = STORAGE_REF.child("message_images")
let STORAGE_MESSAGE_VIDEO_REF = STORAGE_REF.child("video_messages")
let STORAGE_POST_IMAGES_REF = STORAGE_REF.child("post_images")
let STORAGE_POST_VIDEO_REF = STORAGE_REF.child("post_videos")
let STORAGE_STATUS_POST_REF = STORAGE_REF.child("status_posts")
let STORAGE_COMMENT_MEDIA_REF = STORAGE_REF.child("comments_media")

let FUSER_REF = FDB_REF.collection("users")
let FSETTING_REF = FDB_REF.collection("settings")
let FPOSTS_REF = FDB_REF.collection("posts")
let FPIDS_REF = FDB_REF.collection("pids")
let FPIDS_DATE_REF = FDB_REF.collection("pids_new")
let FNOTIFICATIONS_REF = FDB_REF.collection("notifications")
let FHASHTAG_POSTS_REF = FDB_REF.collection("hashtags")
let FCATE_REF = FDB_REF.collection("categories")
let FCHAT_REF = FDB_REF.collection("chatchannels")

let FAMAPI_REF = FDB_REF.collection("amapikey")
let FVERSION_REF = FDB_REF.collection("version")
let FBLOCKED_REF = FDB_REF.collection("blocked")

var ChatChannels: [String: MockChannel] = [:]

// MARK: - Decoding Values

var DBUsers: [String: User] = [:]
var DBPosts: [String: Post] = [:]

var TCount: Int = 0
var DoneCount: Int = 0
var oldChannels: [String: Any] = [:]
var newChannels: [String: Any] = [:]
var THashtags: [String] = []

struct FollowStatus{
    var time: Double
    var followType: FollowType
}

var MyFollowings: [String: FollowStatus] = [:]
var MyBlocks: [String: Bool] = [:]
var MyFollowers: [String: Bool] = [:]
var MyLikedPosts: [String: Bool] = [:]
var MyCommented: [String: Bool] = [:]
var MyLikedComments: [String: Bool] = [:]
var MyCommentedComments: [String: Bool] = [:]

var LoadStepCount: Int = 50

private var currentUserInfo: User!
var Me: User!{
    get{
        if let cid = CUID{
            currentUserInfo.uid = cid
        }
        return currentUserInfo
    }
    set{
        currentUserInfo = newValue
        currentUserInfo.saveLocal()
    }
}

var adminUser: [String] = [
    "lMtZF87ZMcfHZiVJuJB5vcxjyr22", //jamie
    "jpjUEuGEhXS9uw6uGk9AEnN7PDP2", //gilberto
    "uHVg53NJtkXuHxnSugqMpcnQcDX2", //salem
    vipUser
]
var vipUser: String = "Svx3jcpp8lYLivhVot0zof9WJ2W2"
var CUID = Auth.auth().currentUser?.uid
//uHVg53NJtkXuHxnSugqMpcnQcDX2-ceo-cJu8GG1HMgOS0TgfnjGJ0teLWW42
//"" as? String
// MARK: - GIPHY

enum GIPHYConstant {
    static let apiKey = "FGgggC9zsb8PAkHhUee5xEPGEF2pMa97"
}

// MARK: - Size Constants

enum SizeConstant {
    enum CellSize {
        static let MediaCellHeight: CGFloat = 169
        static let StatusCellHeight: CGFloat = 145
        static let GIFCellHeight: CGFloat = 321
    }
}

enum EmailAddress {
    
    static let ReportPost = "report@hiveinc.org"
    static let Support = "support@hiveinc.org"
    
}

var selectedCategoryIndex: Int = -1

var selectedTagIndex: Int = 0

let categories = [
    [//0
        "Cars",
        "cate_cars",
        "All cars from vintage to luxury.",
        ["carshow", "supercar", "racing", "carmeet", "luxurycar", "classiccar", "mercedes", "audi", "porsche", "bmw", "mustang", "ford", "honda", "toyota"]
    ],
    [//1
        "Music",
        "cate_music",
        "For the music lovers",
        ["music", "musicindustry", "vocals", "bestalbum", "newartist", "musicvideo", "discovermusic"]
    ],
    [//2
        "Beauty",
        "cate_beauty",
        "Beauty isn't a hobby, it's a lifestyle",
        ["makeup", "mua", "skincare", "contour", "makeuptutorial", "brows", "lashes", "nails", "makeupaddict", "tutorials", "dragmakeup", "sfxmakeup", "makeupgeek"]
    ],
    [//3
        "Video Games",
        "cate_gaming",
        "Stay up to date with the newest releases and most popular games.",
        ["playstation", "xbox", "nintendo", "twitch", "fortnite", "destiny", "callofduty", "blackops", "reddeadredemption", "streamer", "gamerguy", "gamergirl", "gamerlife", "pcgaming"]
    ],
    [//4
        "Art",
        "cate_art",
        "See other Hive Creators' work",
        ["painting", "digitalart", "graphicdesign", "drawing", "sculptures", "photography", "design", "prints", "sketch", "fanart", "abstractart"]
    ],
    [//5
        "Food",
        "cate_food",
        "Everything Food!",
        ["breakfast", "healthyfood", "cooking", "restaurant", "recipe", "lunch", "starbucks", "vegan", "homemade", "vegetarian", "dinner", "dessert", "chocolate", "drinks", "chef"]
    ],
    [//6
        "Anime",
        "cate_anime",
        "Anime lovers come together",
        ["manga", "cosplay", "kawaii", "animeart", "dragonball", "naruto", "deathnote", "animememes"]
    ],
    [//7
        "LGBTQ+",
        "cate_lgbtq",
        "Welcoming community for LGBTQ+ \npride and Support",
        ["pride", "lgbtq", "loveislove", "gaypride", "lovewins", "equality", "lgbtcommunity", "transgender", "nonbinary", "genderfluid", "asexual"]
    ],
    [//8
        "Horror",
        "cate_horror",
        "Indulge your love for horror from slasher films to Halloween.",
        ["spooky", "halloween", "supernatural", "horrormovie", "thriller", "creepy", "slasher", "zombie", "monster", "scream", "paranormal", "ghosts", "creepypasta"]
    ],
    [//9
        "Memes",
        "cate_meme",
        "Relatable and funny memes and videos to make you laugh out loud anywhere!",
        ["memesdaily", "funnymemes", "lol", "comedy", "memepage", "dankmemes"]
    ],
    [//10
        "Fashion",
        "cate_fashion",
        "Latest Fashion Trends and Outfits of the Day",
        ["ootd", "designer", "handbags", "shopping", "style", "streetwear", "handmade", "merch", "shoes", "accessories", "jewelry"]
    ],
    [//11
        "Pets & Animals",
        "cate_pets",
        "You won't leave this category for hours",
        ["pets", "dog", "cat", "puppies", "rescue", "wildlife", "adopt", "kittens", "reptiles", "bird", "animallovers"]
    ],
    [//12
        "Crafts & DIY",
        "cate_craft",
        "Spark your creativity and share your creations",
        ["diy", "crafting", "handmade", "artsandcrafts", "scrapbooking", "papercraft", "craftideas", "diyideas"]
    ],
    [//13
        "Reading & Literature",
        "cate_reading",
        "Calling all bookworms",
        ["bookworm", "fandoms", "writing", "author", "fanfiction", "currentlyreading", "writer", "goodreads"]
    ],
    [//14
        "Astrology",
        "cate_astrology",
        "A space for astrology enthusiasts",
        ["Astrology", "Zodiac", "Horoscope", "Aries", "Pisces", "Aquarius", "Leo", "Gemini", "Capricorn", "Sagittarius", "Taurus", "Capricorn", "Cancer", "Libra", "Virgo"]
    ],
    [//15
        "Entertainment",
        "cate_entertainment",
        "Keep up with shows, episodes and awards!",
        ["netflix", "comedy", "music", "awards", "hulu", "television", "games", "photography"]
    ],
    [//16
        "Health",
        "cate_health",
        "Stay inspired and motivated for a healthy lifestyle",
        ["fitness", "gym", "yoga", "crossfit", "boxing", "martialarts", "meditation"]
    ],
    [//17
        "Travel",
        "cate_travel",
        "Explore the world",
        ["travel", "vacation", "trip", "travelblogger", "wanderlust", "tourism", "luxuryresort"]
    ],
    [//18
        "Celebs & Influencers",
        "cate_celeb",
        "All about celebrities and influencers.",
        ["viral", "influencer", "trending", "celebs"]
    ],
    [//19
        "Sports",
        "cate_sports",
        "Keep up with sports on HIVE",
        ["basketball", "football", "baseball", "soccer", "sportscenter", "athletes"]
    ],
    [//20
        "Tech & Science",
        "cate_tech",
        "Stay up to date with scientific and technological breakthroughs",
        ["astrophysics", "scientificresearch", "hubbletelescope", "wormhole", "medicalbreakthrough"]
    ],
    [//21
        "Comics & Heros",
        "cate_comics",
        "Home of Marvel, DC, and Indie Comic. \nFans",
        ["DC", "MarvelComics", "avengers", "Ironman", "Superman", "Spiderman", "tonystark", "gamora", "marveluniverse"]
    ]
]
