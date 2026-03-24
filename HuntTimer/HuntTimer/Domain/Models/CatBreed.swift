import Foundation

/// 고양이 품종
/// - rawValue: Realm 저장용 영문 snake_case 식별자
/// - displayName: 화면 표시용 한국어 이름
enum CatBreed: String, CaseIterable {
    case koreanShortHair  = "korean_short_hair"
    case britishShortHair = "british_short_hair"
    case scottishFold     = "scottish_fold"
    case ragdoll          = "ragdoll"
    case persianLongHair  = "persian_long_hair"
    case maineCoon        = "maine_coon"
    case russianBlue      = "russian_blue"
    case siamese          = "siamese"
    case bengal           = "bengal"
    case abyssinian       = "abyssinian"
    case norwegianForest  = "norwegian_forest"
    case munchkin         = "munchkin"
    case birman           = "birman"
    case sphynx           = "sphynx"
    case turkishAngora    = "turkish_angora"
    case mix              = "mix"

    var displayName: String {
        switch self {
        case .koreanShortHair:  return "코리안숏헤어"
        case .britishShortHair: return "브리티시숏헤어"
        case .scottishFold:     return "스코티시폴드"
        case .ragdoll:          return "랙돌"
        case .persianLongHair:  return "페르시안"
        case .maineCoon:        return "메인쿤"
        case .russianBlue:      return "러시안블루"
        case .siamese:          return "샴"
        case .bengal:           return "벵갈"
        case .abyssinian:       return "아비시니안"
        case .norwegianForest:  return "노르웨이숲고양이"
        case .munchkin:         return "먼치킨"
        case .birman:           return "버만"
        case .sphynx:           return "스핑크스"
        case .turkishAngora:    return "터키시앙고라"
        case .mix:              return "모름 / 믹스"
        }
    }

    /// rawValue 문자열로 CatBreed를 복원 (Realm → 도메인 변환)
    static func from(rawValue: String) -> CatBreed? {
        CatBreed(rawValue: rawValue)
    }
}
