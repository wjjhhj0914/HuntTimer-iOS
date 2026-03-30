import Foundation

// MARK: - Hunt Session
struct HuntSession {
    let id: Int
    let time: String
    let title: String       // "[장난감]으로 사냥했어요!" 또는 "열정적으로 사냥했어요!"
    let toy: String         // 원본 장난감 이름 (기록 화면 등에서 사용)
    let toySymbol: String   // SF Symbol 이름 (홈 최근 기록 아이콘)
    let durationText: String
    let durationSeconds: Int
    let calories: Int
    let imageURL: String
}

// MARK: - Achievement Badge
struct Badge {
    let emoji: String
    let label: String
    let desc: String
    let unlocked: Bool
}

// MARK: - Shop Product
struct ShopProduct {
    let id: Int
    let name: String
    let brand: String
    let price: Int
    let rating: Double
    let reviews: Int
    let category: String
    let recommended: Bool
    let recommendReason: String?
    let badge: String
    let imageURL: String
    var isLiked: Bool
}

// MARK: - Adoptable Cat
struct AdoptCat {
    let id: Int
    let name: String
    let age: String
    let gender: String
    let breed: String
    let location: String
    let shelter: String
    let desc: String
    let tags: [String]
    let imageURL: String
    var isLiked: Bool
    let isUrgent: Bool
}

// MARK: - Sample Data
enum SampleData {

    static let sessions: [HuntSession] = [
        HuntSession(id: 1, time: "오전 10:00", title: "깃털 낚싯대로 사냥했어요!",   toy: "깃털 낚싯대",   toySymbol: "leaf.fill",       durationText: "15분", durationSeconds: 900,  calories: 42,  imageURL: ""),
        HuntSession(id: 2, time: "오후 1:30",  title: "방울 공으로 사냥했어요!",     toy: "방울 공",       toySymbol: "pawprint.fill",   durationText: "8분",  durationSeconds: 480,  calories: 18,  imageURL: ""),
        HuntSession(id: 3, time: "오후 3:00",  title: "레이저 포인터로 사냥했어요!", toy: "레이저 포인터", toySymbol: "bolt.fill",        durationText: "12분", durationSeconds: 720,  calories: 30,  imageURL: ""),
        HuntSession(id: 4, time: "오후 7:00",  title: "낚싯대 (털)로 사냥했어요!",  toy: "낚싯대 (털)",   toySymbol: "leaf.fill",       durationText: "20분", durationSeconds: 1200, calories: 56,  imageURL: ""),
        HuntSession(id: 5, time: "오후 9:30",  title: "깃털 낚싯대로 사냥했어요!",  toy: "깃털 낚싯대",   toySymbol: "leaf.fill",       durationText: "10분", durationSeconds: 600,  calories: 25,  imageURL: ""),
    ]

    static let badges: [Badge] = [
        Badge(emoji: "🏆", label: "사냥 마스터",  desc: "100회 달성",    unlocked: true),
        Badge(emoji: "🪶", label: "깃털 광팬",    desc: "깃털 30회",     unlocked: true),
        Badge(emoji: "🔥", label: "연속 7일",     desc: "7일 연속",      unlocked: true),
        Badge(emoji: "⚡", label: "번개 냥이",    desc: "5분 이내 10회", unlocked: true),
        Badge(emoji: "🌙", label: "야행성",       desc: "밤 사냥 20회",  unlocked: false),
        Badge(emoji: "🎯", label: "퍼펙트",       desc: "목표 30일",     unlocked: false),
        Badge(emoji: "💎", label: "다이아",       desc: "총 50시간",     unlocked: false),
        Badge(emoji: "🌟", label: "슈퍼스타",     desc: "모든 배지",     unlocked: false),
    ]

    static var products: [ShopProduct] = [
        ShopProduct(id: 1, name: "프리미엄 깃털 낚싯대", brand: "캣조이",   price: 12900, rating: 4.8, reviews: 1243,
                    category: "깃털",   recommended: true,  recommendReason: "뮤기의 사냥 기록 기반 추천",
                    badge: "🏆 베스트셀러",
                    imageURL: "https://images.unsplash.com/photo-1586789544845-bbb76c0c67c4?w=400", isLiked: false),
        ShopProduct(id: 2, name: "냥이 군것질 트릿",    brand: "퓨리나",   price: 8500,  rating: 4.6, reviews: 889,
                    category: "간식",   recommended: true,  recommendReason: "활동 후 보상용 간식",
                    badge: "🌟 추천",
                    imageURL: "https://images.unsplash.com/photo-1594475161965-b711112b6942?w=400", isLiked: true),
        ShopProduct(id: 3, name: "반짝 방울 공 세트",   brand: "펫플",     price: 6500,  rating: 4.3, reviews: 456,
                    category: "공",     recommended: false, recommendReason: nil,
                    badge: "",
                    imageURL: "https://images.unsplash.com/photo-1691351943492-cfee023e9cbf?w=400", isLiked: false),
        ShopProduct(id: 4, name: "고양이 스크래처 터널", brand: "냥이월드", price: 24900, rating: 4.9, reviews: 2341,
                    category: "장난감", recommended: true,  recommendReason: "뮤기가 좋아할 것 같아요!",
                    badge: "🔥 인기",
                    imageURL: "https://images.unsplash.com/photo-1744710835733-936ab49ee0b4?w=400", isLiked: false),
        ShopProduct(id: 5, name: "레이저 포인터 자동",  brand: "펫테크",   price: 18900, rating: 4.5, reviews: 672,
                    category: "장난감", recommended: false, recommendReason: nil,
                    badge: "⚡ 신상",
                    imageURL: "https://images.unsplash.com/photo-1716487621020-462aa91a6af6?w=400", isLiked: false),
        ShopProduct(id: 6, name: "천연 모 깃털 리필",   brand: "캣조이",   price: 4500,  rating: 4.7, reviews: 334,
                    category: "깃털",   recommended: false, recommendReason: nil,
                    badge: "",
                    imageURL: "https://images.unsplash.com/photo-1702914954859-f037fc75b760?w=400", isLiked: true),
    ]

    static var adoptCats: [AdoptCat] = [
        AdoptCat(id: 1, name: "솜사탕", age: "2개월", gender: "암컷", breed: "코리안숏헤어",
                 location: "서울 마포구", shelter: "서울동물복지센터",
                 desc: "아직 아기지만 용감한 아이예요. 처음엔 낯을 가리지만 금방 무릎 위에 올라와요 💕",
                 tags: ["아기냥", "순둥이", "첫고양이 추천"],
                 imageURL: "https://images.unsplash.com/photo-1767363876659-cf0c13254a64?w=400",
                 isLiked: false, isUrgent: true),
        AdoptCat(id: 2, name: "까만콩", age: "3살",   gender: "수컷", breed: "코리안숏헤어",
                 location: "경기 성남시", shelter: "성남동물보호센터",
                 desc: "검은 고양이는 행운을 가져다준다고 해요. 장난감을 정말 좋아해요 🖤",
                 tags: ["활발", "놀기 좋아함", "건강함"],
                 imageURL: "https://images.unsplash.com/photo-1553006100-21358fe1f19a?w=400",
                 isLiked: true, isUrgent: false),
        AdoptCat(id: 3, name: "두부",   age: "1살",   gender: "수컷", breed: "코리안숏헤어",
                 location: "서울 은평구", shelter: "서울유기동물센터",
                 desc: "두부처럼 하얗고 부드러운 아이예요. 조용하고 차분하며 책 읽는 당신 곁에 꼭 맞아요 📖",
                 tags: ["순함", "조용함", "1인가구 추천"],
                 imageURL: "https://images.unsplash.com/photo-1568799023141-5d0c6811aba0?w=400",
                 isLiked: false, isUrgent: false),
        AdoptCat(id: 4, name: "도토리", age: "6개월", gender: "암컷", breed: "코리안숏헤어",
                 location: "인천 남동구", shelter: "인천시 동물보호소",
                 desc: "도토리는 에너지가 넘치는 아이예요. 집을 활기차게 해줄 장난꾸러기! 🌰",
                 tags: ["활발", "귀여움", "장난꾸러기"],
                 imageURL: "https://images.unsplash.com/photo-1716487621020-462aa91a6af6?w=400",
                 isLiked: false, isUrgent: true),
    ]
}
