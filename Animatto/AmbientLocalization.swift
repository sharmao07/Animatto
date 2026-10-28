import Foundation

// MARK: - Supported Localization Languages (11 Languages)
public enum AmbientLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case hindi = "hi"
    case japanese = "ja"
    case korean = "ko"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case brazilianPortuguese = "pt-BR"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "हिन्दी (Hindi)"
        case .japanese: return "日本語 (Japanese)"
        case .korean: return "한국어 (Korean)"
        case .simplifiedChinese: return "简体中文 (Simplified Chinese)"
        case .traditionalChinese: return "繁體中文 (Traditional Chinese)"
        case .spanish: return "Español (Spanish)"
        case .french: return "Français (French)"
        case .german: return "Deutsch (German)"
        case .italian: return "Italiano (Italian)"
        case .brazilianPortuguese: return "Português do Brasil (Portuguese)"
        }
    }
}

// MARK: - Ambient Localization Dictionary
public struct AmbientLocalization {
    public static var currentLanguage: AmbientLanguage = .english
    
    private static let translations: [AmbientLanguage: [String: String]] = [
        .english: [
            "env.rain": "Gentle Rain",
            "env.snow": "Quiet Snow",
            "env.fog": "Misty Fog",
            "env.sunlight": "Golden Sunlight",
            "env.wind": "Breezy Wind",
            "env.fallingLeaves": "Autumn Leaves",
            
            "preset.rainy_evening": "Rainy Evening",
            "preset.first_snow": "First Snow",
            "preset.autumn_window": "Autumn Window",
            "preset.golden_morning": "Golden Morning",
            "preset.quiet_night": "Quiet Night",
            "preset.misty_forest": "Misty Forest",
            
            "ui.ambience_title": "Ambient Worlds",
            "ui.enable_ambience": "Enable Desktop Atmosphere",
            "ui.intensity": "Atmosphere Intensity",
            "ui.quality_mode": "Visual Quality Mode",
            "ui.minigame_title": "Ambient Collectibles Minigame",
            "ui.score": "Session Score",
            "ui.high_score": "High Score",
            "ui.weather_sync": "Live Weather Synchronization",
            "ui.inverse_mode": "Inverse Weather Mode",
            "ui.packs": "Atmosphere Packs",
            "ui.clear_location": "Clear Saved Location"
        ],
        .hindi: [
            "env.rain": "रिमझिम बारिश",
            "env.snow": "शांत बर्फबारी",
            "env.fog": "धुंधला कोहरा",
            "env.sunlight": "सुनहरी धूप",
            "env.wind": "मंद बयार",
            "env.fallingLeaves": "पतझड़ के पत्ते",
            
            "preset.rainy_evening": "बरसात की शाम",
            "preset.first_snow": "पहली बर्फबारी",
            "preset.autumn_window": "पतझड़ की खिड़की",
            "preset.golden_morning": "सुनहरी सुबह",
            "preset.quiet_night": "शांत रात",
            "preset.misty_forest": "धुंधला जंगल",
            
            "ui.ambience_title": "परिवेशी दुनिया",
            "ui.enable_ambience": "डेस्कटॉप वातावरण सक्षम करें",
            "ui.intensity": "वातावरण की तीव्रता",
            "ui.quality_mode": "दृश्य गुणवत्ता मोड",
            "ui.minigame_title": "परिवेशी संग्रहणीय मिनीगेम",
            "ui.score": "सत्र स्कोर",
            "ui.high_score": "सर्वश्रेष्ठ स्कोर",
            "ui.weather_sync": "लाइव मौसम समन्वय",
            "ui.inverse_mode": "विपरीत मौसम मोड",
            "ui.packs": "वातावरण पैक",
            "ui.clear_location": "सहेजा गया स्थान साफ़ करें"
        ],
        .japanese: [
            "env.rain": "静かな雨",
            "env.snow": "穏やかな雪",
            "env.fog": "深い霧",
            "env.sunlight": "黄金色の木漏れ日",
            "env.wind": "そよ風",
            "env.fallingLeaves": "秋の紅葉",
            
            "preset.rainy_evening": "雨の夕暮れ",
            "preset.first_snow": "初雪の便り",
            "preset.autumn_window": "秋の窓辺",
            "preset.golden_morning": "黄金の朝光",
            "preset.quiet_night": "静かな夜想",
            "preset.misty_forest": "霧立ちの森",
            
            "ui.ambience_title": "アンビエントワールド",
            "ui.enable_ambience": "デスクトップ環境効果を有効化",
            "ui.intensity": "環境効果の強さ",
            "ui.quality_mode": "描画クオリティ",
            "ui.minigame_title": "浮遊アイテム収集ミニゲーム",
            "ui.score": "セッションスコア",
            "ui.high_score": "ハイスコア",
            "ui.weather_sync": "リアルタイム天気同期",
            "ui.inverse_mode": "インバース（逆転）ウェザーモード",
            "ui.packs": "雰囲気プリセットパック",
            "ui.clear_location": "保存した位置情報を削除"
        ],
        .korean: [
            "env.rain": "포근한 비",
            "env.snow": "고요한 눈",
            "env.fog": "자욱한 안개",
            "env.sunlight": "따사로운 햇살",
            "env.wind": "상쾌한 바람",
            "env.fallingLeaves": "흩날리는 낙엽",
            
            "preset.rainy_evening": "비 내리는 저녁",
            "preset.first_snow": "첫눈 내리는 날",
            "preset.autumn_window": "가을 창가",
            "preset.golden_morning": "황금빛 아침",
            "preset.quiet_night": "고요한 밤",
            "preset.misty_forest": "안개 낀 숲",
            
            "ui.ambience_title": "앰비언트 월드",
            "ui.enable_ambience": "데스크톱 분위기 활성화",
            "ui.intensity": "분위기 강도",
            "ui.quality_mode": "그래픽 품질 모드",
            "ui.minigame_title": "아이템 수집 미니게임",
            "ui.score": "현재 점수",
            "ui.high_score": "최고 점수",
            "ui.weather_sync": "실시간 날씨 동기화",
            "ui.inverse_mode": "반전 날씨 모드",
            "ui.packs": "테마 팩",
            "ui.clear_location": "저장된 위치 삭제"
        ],
        .simplifiedChinese: [
            "env.rain": "淅沥细雨",
            "env.snow": "静谧飘雪",
            "env.fog": "薄雾缭绕",
            "env.sunlight": "金煦阳光",
            "env.wind": "轻柔清风",
            "env.fallingLeaves": "漫舞秋叶",
            
            "preset.rainy_evening": "雨夜微凉",
            "preset.first_snow": "初雪降临",
            "preset.autumn_window": "秋日窗畔",
            "preset.golden_morning": "金色晨曦",
            "preset.quiet_night": "静谧之夜",
            "preset.misty_forest": "雾林幽境",
            
            "ui.ambience_title": "氛围世界",
            "ui.enable_ambience": "开启桌面氛围特效",
            "ui.intensity": "氛围浓度",
            "ui.quality_mode": "画质模式",
            "ui.minigame_title": "漂浮物收集小游戏",
            "ui.score": "本局得分",
            "ui.high_score": "最高纪录",
            "ui.weather_sync": "实时天气同步",
            "ui.inverse_mode": "反转天气模式",
            "ui.packs": "氛围扩展包",
            "ui.clear_location": "清除已存位置"
        ],
        .traditionalChinese: [
            "env.rain": "綿綿細雨",
            "env.snow": "靜謐飄雪",
            "env.fog": "薄霧瀰漫",
            "env.sunlight": "溫煦陽光",
            "env.wind": "輕柔微風",
            "env.fallingLeaves": "秋楓落葉",
            
            "preset.rainy_evening": "雨夜時分",
            "preset.first_snow": "初雪降臨",
            "preset.autumn_window": "秋日窗扉",
            "preset.golden_morning": "金色晨光",
            "preset.quiet_night": "沉靜夜色",
            "preset.misty_forest": "霧林深處",
            
            "ui.ambience_title": "氛圍世界",
            "ui.enable_ambience": "啟用桌面氛圍特效",
            "ui.intensity": "氛圍強度",
            "ui.quality_mode": "畫質模式",
            "ui.minigame_title": "飄浮物收集迷你遊戲",
            "ui.score": "本次得分",
            "ui.high_score": "最高紀錄",
            "ui.weather_sync": "即時天氣同步",
            "ui.inverse_mode": "反轉天氣模式",
            "ui.packs": "氛圍擴充包",
            "ui.clear_location": "清除已存位置"
        ],
        .spanish: [
            "env.rain": "Lluvia Suave",
            "env.snow": "Nieve Serena",
            "env.fog": "Niebla Matutina",
            "env.sunlight": "Luz Solar Dorada",
            "env.wind": "Brisa Agradable",
            "env.fallingLeaves": "Hojas de Otoño",
            
            "preset.rainy_evening": "Tarde Lluviosa",
            "preset.first_snow": "Primera Nevada",
            "preset.autumn_window": "Ventana Otoñal",
            "preset.golden_morning": "Mañana Dorada",
            "preset.quiet_night": "Noche Tranquila",
            "preset.misty_forest": "Bosque Nublado",
            
            "ui.ambience_title": "Mundos Ambientales",
            "ui.enable_ambience": "Activar Atmósfera de Escritorio",
            "ui.intensity": "Intensidad Atmosférica",
            "ui.quality_mode": "Modo de Calidad",
            "ui.minigame_title": "Minijuego de Recolección",
            "ui.score": "Puntuación de Sesión",
            "ui.high_score": "Récord",
            "ui.weather_sync": "Sincronización Meteorológica",
            "ui.inverse_mode": "Modo de Clima Inverso",
            "ui.packs": "Paquetes de Atmósfera",
            "ui.clear_location": "Borrar Ubicación Guardada"
        ],
        .french: [
            "env.rain": "Pluie Douce",
            "env.snow": "Neige Paisible",
            "env.fog": "Brume Légère",
            "env.sunlight": "Lumière Dorée",
            "env.wind": "Brise Fraîche",
            "env.fallingLeaves": "Feuilles d'Automne",
            
            "preset.rainy_evening": "Soirée Pluvieuse",
            "preset.first_snow": "Première Neige",
            "preset.autumn_window": "Fenêtre d'Automne",
            "preset.golden_morning": "Matin Doré",
            "preset.quiet_night": "Nuit Calme",
            "preset.misty_forest": "Forêt Brumeuse",
            
            "ui.ambience_title": "Mondes Ambiants",
            "ui.enable_ambience": "Activer l'Atmosphère",
            "ui.intensity": "Intensité",
            "ui.quality_mode": "Qualité Visuelle",
            "ui.minigame_title": "Mini-jeu d'Objets Flottants",
            "ui.score": "Score",
            "ui.high_score": "Meilleur Score",
            "ui.weather_sync": "Météo en Direct",
            "ui.inverse_mode": "Mode Météo Inversée",
            "ui.packs": "Packs d'Ambiance",
            "ui.clear_location": "Effacer la Position"
        ],
        .german: [
            "env.rain": "Sanfter Regen",
            "env.snow": "Stiller Schnee",
            "env.fog": "Nebelzauber",
            "env.sunlight": "Goldener Sonnenschein",
            "env.wind": "Frische Brise",
            "env.fallingLeaves": "Herbstblätter",
            
            "preset.rainy_evening": "Regnerischer Abend",
            "preset.first_snow": "Erster Schnee",
            "preset.autumn_window": "Herbstfenster",
            "preset.golden_morning": "Goldener Morgen",
            "preset.quiet_night": "Ruhige Nacht",
            "preset.misty_forest": "Nebelwald",
            
            "ui.ambience_title": "Atmosphärische Welten",
            "ui.enable_ambience": "Desktop-Atmosphäre aktivieren",
            "ui.intensity": "Effektstärke",
            "ui.quality_mode": "Qualitätsmodus",
            "ui.minigame_title": "Sammel-Minispiel",
            "ui.score": "Punktestand",
            "ui.high_score": "Highscore",
            "ui.weather_sync": "Live-Wetter-Synchronisation",
            "ui.inverse_mode": "Inverser Wettermodus",
            "ui.packs": "Atmosphären-Pakete",
            "ui.clear_location": "Gespeicherten Ort löschen"
        ],
        .italian: [
            "env.rain": "Pioggia Leggera",
            "env.snow": "Neve Silenziosa",
            "env.fog": "Nebbia Mattutina",
            "env.sunlight": "Luce Dorata",
            "env.wind": "Brezza Leggera",
            "env.fallingLeaves": "Foglie d'Autunno",
            
            "preset.rainy_evening": "Serata di Pioggia",
            "preset.first_snow": "Prima Neve",
            "preset.autumn_window": "Finestra d'Autunno",
            "preset.golden_morning": "Mattino Dorato",
            "preset.quiet_night": "Notte Serena",
            "preset.misty_forest": "Foresta Nebbiosa",
            
            "ui.ambience_title": "Mondi Ambientali",
            "ui.enable_ambience": "Attiva Atmosfera Desktop",
            "ui.intensity": "Intensità Atmosfera",
            "ui.quality_mode": "Modalità Qualità",
            "ui.minigame_title": "Minigioco Raccolta",
            "ui.score": "Punteggio",
            "ui.high_score": "Miglior Punteggio",
            "ui.weather_sync": "Sincronizzazione Meteo",
            "ui.inverse_mode": "Modalità Meteo Inversa",
            "ui.packs": "Pacchetti Atmosfera",
            "ui.clear_location": "Cancella Posizione"
        ],
        .brazilianPortuguese: [
            "env.rain": "Chuva Suave",
            "env.snow": "Neve Tranquila",
            "env.fog": "Névoa Suave",
            "env.sunlight": "Luz Solar Dourada",
            "env.wind": "Brisa Agradável",
            "env.fallingLeaves": "Folhas de Outono",
            
            "preset.rainy_evening": "Tarde Chuvosa",
            "preset.first_snow": "Primeira Neve",
            "preset.autumn_window": "Janela de Outono",
            "preset.golden_morning": "Manhã Dourada",
            "preset.quiet_night": "Noite Tranquila",
            "preset.misty_forest": "Floresta Nebulosa",
            
            "ui.ambience_title": "Mundos Ambientes",
            "ui.enable_ambience": "Ativar Atmosfera de Área de Trabalho",
            "ui.intensity": "Intensidade da Atmosfera",
            "ui.quality_mode": "Modo de Qualidade",
            "ui.minigame_title": "Minijogo de Coleta",
            "ui.score": "Pontuação da Sessão",
            "ui.high_score": "Recorde",
            "ui.weather_sync": "Sincronização Meteorológica",
            "ui.inverse_mode": "Modo de Clima Inverso",
            "ui.packs": "Pacotes de Atmosfera",
            "ui.clear_location": "Limpar Localização Salva"
        ]
    ]
    
    public static func localized(_ key: String, language: AmbientLanguage? = nil) -> String {
        let lang = language ?? currentLanguage
        if let text = translations[lang]?[key] {
            return text
        }
        // Fallback to English
        return translations[.english]?[key] ?? key
    }
}
