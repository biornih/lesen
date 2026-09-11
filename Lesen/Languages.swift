//  Languages.swift
//  Mother tongues, target languages, flat flags, and the UI string table.

import SwiftUI

// MARK: - Mother tongue

struct MotherTongue: Identifiable, Hashable {
    let code: String
    let endonym: String     // the language written in itself
    let english: String
    var id: String { code }
}

enum Languages {

    static let motherTongues: [MotherTongue] = [
        .init(code: "sq",      endonym: "Shqip",            english: "Albanian"),
        .init(code: "ar",      endonym: "العربية",           english: "Arabic"),
        .init(code: "bn",      endonym: "বাংলা",              english: "Bengali"),
        .init(code: "bg",      endonym: "Български",         english: "Bulgarian"),
        .init(code: "zh-Hans", endonym: "简体中文",            english: "Chinese (Simplified)"),
        .init(code: "zh-Hant", endonym: "繁體中文",            english: "Chinese (Traditional)"),
        .init(code: "hr",      endonym: "Hrvatski",         english: "Croatian"),
        .init(code: "cs",      endonym: "Čeština",          english: "Czech"),
        .init(code: "da",      endonym: "Dansk",            english: "Danish"),
        .init(code: "nl",      endonym: "Nederlands",       english: "Dutch"),
        .init(code: "en",      endonym: "English",          english: "English"),
        .init(code: "et",      endonym: "Eesti",            english: "Estonian"),
        .init(code: "fi",      endonym: "Suomi",            english: "Finnish"),
        .init(code: "fr",      endonym: "Français",         english: "French"),
        .init(code: "ka",      endonym: "ქართული",           english: "Georgian"),
        .init(code: "de",      endonym: "Deutsch",          english: "German"),
        .init(code: "el",      endonym: "Ελληνικά",          english: "Greek"),
        .init(code: "hi",      endonym: "हिन्दी",              english: "Hindi"),
        .init(code: "hu",      endonym: "Magyar",           english: "Hungarian"),
        .init(code: "id",      endonym: "Bahasa Indonesia", english: "Indonesian"),
        .init(code: "it",      endonym: "Italiano",         english: "Italian"),
        .init(code: "ja",      endonym: "日本語",             english: "Japanese"),
        .init(code: "ko",      endonym: "한국어",             english: "Korean"),
        .init(code: "lv",      endonym: "Latviešu",         english: "Latvian"),
        .init(code: "lt",      endonym: "Lietuvių",         english: "Lithuanian"),
        .init(code: "mk",      endonym: "Македонски",        english: "Macedonian"),
        .init(code: "ms",      endonym: "Bahasa Melayu",    english: "Malay"),
        .init(code: "no",      endonym: "Norsk",            english: "Norwegian"),
        .init(code: "fa",      endonym: "فارسی",             english: "Persian"),
        .init(code: "pl",      endonym: "Polski",           english: "Polish"),
        .init(code: "pt",      endonym: "Português",        english: "Portuguese"),
        .init(code: "ro",      endonym: "Română",           english: "Romanian"),
        .init(code: "ru",      endonym: "Русский",           english: "Russian"),
        .init(code: "sr",      endonym: "Српски",            english: "Serbian"),
        .init(code: "sk",      endonym: "Slovenčina",       english: "Slovak"),
        .init(code: "sl",      endonym: "Slovenščina",      english: "Slovenian"),
        .init(code: "es",      endonym: "Español",          english: "Spanish"),
        .init(code: "sw",      endonym: "Kiswahili",        english: "Swahili"),
        .init(code: "sv",      endonym: "Svenska",          english: "Swedish"),
        .init(code: "th",      endonym: "ไทย",               english: "Thai"),
        .init(code: "tr",      endonym: "Türkçe",           english: "Turkish"),
        .init(code: "uk",      endonym: "Українська",        english: "Ukrainian"),
        .init(code: "ur",      endonym: "اردو",              english: "Urdu"),
        .init(code: "vi",      endonym: "Tiếng Việt",       english: "Vietnamese"),
    ]

    static var deviceDefault: MotherTongue {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return motherTongues.first { $0.code.hasPrefix(code) }
            ?? motherTongues.first { $0.code == "en" }!
    }

    static func motherTongue(code: String) -> MotherTongue {
        motherTongues.first { $0.code == code } ?? deviceDefault
    }
}

// MARK: - Target language

struct TargetLanguage: Identifiable, Hashable {
    let code: String
    let endonym: String
    let english: String
    let available: Bool
    var id: String { code }
}

extension Languages {
    static let targets: [TargetLanguage] = [
        .init(code: "de", endonym: "Deutsch",  english: "German",  available: true),
        .init(code: "fr", endonym: "Français", english: "French",  available: false),
        .init(code: "es", endonym: "Español",  english: "Spanish", available: false),
        .init(code: "it", endonym: "Italiano", english: "Italian", available: false),
        .init(code: "ru", endonym: "Русский",  english: "Russian", available: false),
        .init(code: "tr", endonym: "Türkçe",   english: "Turkish", available: false),
    ]

    static func target(code: String) -> TargetLanguage {
        targets.first { $0.code == code } ?? targets[0]
    }
}

// MARK: - Flat flags (no emoji)

struct FlagMark: View {
    let code: String
    var width: CGFloat = 34

    private var height: CGFloat { width * 0.68 }

    var body: some View {
        Group {
            switch code {
            case "de": stripes(.horizontal, [.black, Color(red: 0.86, green: 0.13, blue: 0.15), Color(red: 1.0, green: 0.81, blue: 0.11)])
            case "fr": stripes(.vertical,   [Color(red: 0.0, green: 0.21, blue: 0.53), .white, Color(red: 0.93, green: 0.16, blue: 0.22)])
            case "it": stripes(.vertical,   [Color(red: 0.0, green: 0.56, blue: 0.27), .white, Color(red: 0.81, green: 0.18, blue: 0.19)])
            case "ru": stripes(.horizontal, [.white, Color(red: 0.0, green: 0.22, blue: 0.65), Color(red: 0.84, green: 0.13, blue: 0.16)])
            case "es": spain
            case "tr": turkey
            default:   Rectangle().fill(Color.secondary.opacity(0.3))
            }
        }
        .frame(width: width, height: height)
        .clipShape(.rect(cornerRadius: width * 0.13))
        .overlay(
            RoundedRectangle(cornerRadius: width * 0.13)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.6)
        )
    }

    private func stripes(_ axis: Axis, _ colors: [Color]) -> some View {
        Group {
            if axis == .horizontal {
                VStack(spacing: 0) { ForEach(colors.indices, id: \.self) { colors[$0] } }
            } else {
                HStack(spacing: 0) { ForEach(colors.indices, id: \.self) { colors[$0] } }
            }
        }
    }

    private var spain: some View {
        VStack(spacing: 0) {
            Color(red: 0.67, green: 0.10, blue: 0.16)
            Color(red: 1.0, green: 0.77, blue: 0.0).frame(height: height * 0.5)
            Color(red: 0.67, green: 0.10, blue: 0.16)
        }
    }

    private var turkey: some View {
        ZStack {
            Color(red: 0.89, green: 0.10, blue: 0.14)
            HStack(spacing: width * 0.03) {
                Circle()
                    .fill(.white)
                    .frame(width: height * 0.42)
                    .overlay(
                        Circle()
                            .fill(Color(red: 0.89, green: 0.10, blue: 0.14))
                            .frame(width: height * 0.33)
                            .offset(x: height * 0.09)
                    )
                Image(systemName: "star.fill")
                    .font(.system(size: height * 0.2))
                    .foregroundStyle(.white)
            }
            .offset(x: -width * 0.04)
        }
    }
}

// MARK: - UI strings
//
// Full coverage for en/de/sq/tr/es/fr/it/ru; other languages fall back to
// English until a String Catalog replaces this.

enum L {
    static func t(_ key: String, _ lang: String) -> String {
        table[key]?[lang] ?? table[key]?["en"] ?? key
    }

    private static let table: [String: [String: String]] = [


        // genres & pairings
        "genre_romance": ["en":"Romance","de":"Liebesroman","sq":"Romancë","tr":"Romantik","es":"Romance","fr":"Romance","it":"Romance","ru":"Романтика"],
        "genre_romance_sub": ["en":"Slow-burn love stories","de":"Slow-burn Liebesgeschichten","sq":"Histori dashurie që ndizen ngadalë","tr":"Yavaş yanan aşk hikâyeleri","es":"Historias de amor a fuego lento","fr":"Histoires d'amour qui prennent leur temps","it":"Storie d'amore a fuoco lento","ru":"Медленно разгорающиеся истории любви"],
        "genre_mystery": ["en":"Mystery","de":"Krimi","sq":"Mister","tr":"Polisiye","es":"Misterio","fr":"Policier","it":"Giallo","ru":"Детектив"],
        "genre_fantasy": ["en":"Fantasy","de":"Fantasy","sq":"Fantazi","tr":"Fantastik","es":"Fantasía","fr":"Fantasy","it":"Fantasy","ru":"Фэнтези"],
        "genre_scifi": ["en":"Science Fiction","de":"Science-Fiction","sq":"Fantashkencë","tr":"Bilim Kurgu","es":"Ciencia ficción","fr":"Science-fiction","it":"Fantascienza","ru":"Научная фантастика"],
        "genre_horror": ["en":"Horror","de":"Horror","sq":"Horror","tr":"Korku","es":"Terror","fr":"Horreur","it":"Horror","ru":"Ужасы"],
        "pair_mw_desc": ["en":"Love stories between a man and a woman.","de":"Liebesgeschichten zwischen einem Mann und einer Frau.","sq":"Histori dashurie mes një burri dhe një gruaje.","tr":"Bir erkek ve bir kadın arasındaki aşk hikâyeleri.","es":"Historias de amor entre un hombre y una mujer.","fr":"Histoires d'amour entre un homme et une femme.","it":"Storie d'amore tra un uomo e una donna.","ru":"Истории любви между мужчиной и женщиной."],
        "pair_mm_desc": ["en":"Love stories between two men.","de":"Liebesgeschichten zwischen zwei Männern.","sq":"Histori dashurie mes dy burrave.","tr":"İki erkek arasındaki aşk hikâyeleri.","es":"Historias de amor entre dos hombres.","fr":"Histoires d'amour entre deux hommes.","it":"Storie d'amore tra due uomini.","ru":"Истории любви между двумя мужчинами."],
        "pair_ww_desc": ["en":"Love stories between two women.","de":"Liebesgeschichten zwischen zwei Frauen.","sq":"Histori dashurie mes dy grave.","tr":"İki kadın arasındaki aşk hikâyeleri.","es":"Historias de amor entre dos mujeres.","fr":"Histoires d'amour entre deux femmes.","it":"Storie d'amore tra due donne.","ru":"Истории любви между двумя женщинами."],
        "series_tbw_tag": ["en":"Not written yet — coming soon.","de":"Noch nicht geschrieben — bald verfügbar.","sq":"Ende e pashkruar — së shpejti.","tr":"Henüz yazılmadı — yakında.","es":"Aún no escrito: próximamente.","fr":"Pas encore écrit — bientôt.","it":"Non ancora scritto — prossimamente.","ru":"Ещё не написано — скоро."],
        // levels
        "lvl_a1_title": ["en":"Beginner","de":"Anfänger","sq":"Fillestar","tr":"Başlangıç","es":"Principiante","fr":"Débutant","it":"Principiante","ru":"Начальный"],
        "lvl_a2_title": ["en":"Basics","de":"Grundlagen","sq":"Bazat","tr":"Temel","es":"Básico","fr":"Bases","it":"Base","ru":"Базовый"],
        "lvl_b1_title": ["en":"Intermediate","de":"Mittelstufe","sq":"Mesatar","tr":"Orta","es":"Intermedio","fr":"Intermédiaire","it":"Intermedio","ru":"Средний"],
        "lvl_b2_title": ["en":"Advanced","de":"Fortgeschritten","sq":"I avancuar","tr":"İleri","es":"Avanzado","fr":"Avancé","it":"Avanzato","ru":"Продвинутый"],
        "lvl_c1_title": ["en":"Very advanced","de":"Sehr fortgeschritten","sq":"Shumë i avancuar","tr":"Çok ileri","es":"Muy avanzado","fr":"Très avancé","it":"Molto avanzato","ru":"Очень продвинутый"],
        "lvl_a1_blurb": ["en":"I know a few words.","de":"Ich kenne ein paar Wörter.","sq":"Di disa fjalë.","tr":"Birkaç kelime biliyorum.","es":"Sé algunas palabras.","fr":"Je connais quelques mots.","it":"Conosco qualche parola.","ru":"Знаю несколько слов."],
        "lvl_a2_blurb": ["en":"I understand simple sentences.","de":"Einfache Sätze verstehe ich.","sq":"Kuptoj fjali të thjeshta.","tr":"Basit cümleleri anlıyorum.","es":"Entiendo frases sencillas.","fr":"Je comprends les phrases simples.","it":"Capisco frasi semplici.","ru":"Понимаю простые предложения."],
        "lvl_b1_blurb": ["en":"I get by in everyday situations.","de":"Ich komme im Alltag zurecht.","sq":"Ia dal në jetën e përditshme.","tr":"Günlük hayatta idare ederim.","es":"Me manejo en el día a día.","fr":"Je me débrouille au quotidien.","it":"Me la cavo nella vita quotidiana.","ru":"Справляюсь в быту."],
        "lvl_b2_blurb": ["en":"I read and speak fairly freely.","de":"Ich lese und rede ziemlich frei.","sq":"Lexoj dhe flas mjaft lirshëm.","tr":"Oldukça rahat okuyup konuşurum.","es":"Leo y hablo con bastante soltura.","fr":"Je lis et parle assez librement.","it":"Leggo e parlo abbastanza liberamente.","ru":"Читаю и говорю довольно свободно."],
        "lvl_c1_blurb": ["en":"Almost everything — just the polish is missing.","de":"Fast alles — es fehlt der Feinschliff.","sq":"Pothuajse gjithçka — mungon vetëm lustra.","tr":"Neredeyse her şey — sadece incelik eksik.","es":"Casi todo, solo falta pulirlo.","fr":"Presque tout — il manque la finition.","it":"Quasi tutto — manca solo la rifinitura.","ru":"Почти всё — не хватает шлифовки."],

        // genres & series copy
        "genre_bl_sub": ["en":"Slow-burn love stories","de":"Slow-burn Liebesgeschichten","sq":"Histori dashurie që ndizen ngadalë","tr":"Yavaş yanan aşk hikâyeleri","es":"Historias de amor a fuego lento","fr":"Histoires d'amour qui prennent leur temps","it":"Storie d'amore a fuoco lento","ru":"Медленно разгорающиеся истории любви"],
        "genre_krimi": ["en":"Crime","de":"Krimi","sq":"Krimi","tr":"Polisiye","es":"Novela negra","fr":"Policier","it":"Giallo","ru":"Детектив"],
        "genre_lit": ["en":"Literary","de":"Literarisch","sq":"Letrare","tr":"Edebî","es":"Literaria","fr":"Littéraire","it":"Letterario","ru":"Литературная проза"],
        "series_zu_tag": ["en":"Four love stories in one city on the river.","de":"Vier Liebesgeschichten in einer Stadt am Fluss.","sq":"Katër histori dashurie në një qytet buzë lumit.","tr":"Nehir kıyısındaki bir şehirde dört aşk hikâyesi.","es":"Cuatro historias de amor en una ciudad junto al río.","fr":"Quatre histoires d'amour dans une ville au bord du fleuve.","it":"Quattro storie d'amore in una città sul fiume.","ru":"Четыре истории любви в городе у реки."],
        "series_nds_tag": ["en":"Three volumes. Harder, faster, more grown-up.","de":"Drei Bände. Schwerer, schneller, erwachsener.","sq":"Tre vëllime. Më e vështirë, më e shpejtë, më e rritur.","tr":"Üç cilt. Daha zor, daha hızlı, daha yetişkin.","es":"Tres volúmenes. Más difícil, más rápido, más adulto.","fr":"Trois tomes. Plus difficile, plus rapide, plus adulte.","it":"Tre volumi. Più difficile, più veloce, più adulto.","ru":"Три тома. Сложнее, быстрее, взрослее."],
        "series_lls_tag": ["en":"Literary C1. No more compromises.","de":"Literarisches C1. Kein Kompromiss mehr.","sq":"C1 letrar. Pa më kompromis.","tr":"Edebî C1. Artık taviz yok.","es":"C1 literario. Sin más concesiones.","fr":"C1 littéraire. Plus aucun compromis.","it":"C1 letterario. Nessun compromesso.","ru":"Литературный C1. Больше никаких компромиссов."],

        // import flow
        "detectedTarget": ["en":"Detected language: **%@**. You'll read the original; the translation layer is generated.","de":"Erkannte Sprache: **%@**. Du liest das Original; die Übersetzungsebene wird erzeugt.","sq":"Gjuha e zbuluar: **%@**. Do të lexosh origjinalin; shtresa e përkthimit gjenerohet.","tr":"Algılanan dil: **%@**. Orijinali okuyacaksın; çeviri katmanı oluşturulur.","es":"Idioma detectado: **%@**. Leerás el original; la capa de traducción se genera.","fr":"Langue détectée : **%@**. Vous lirez l'original ; la couche de traduction est générée.","it":"Lingua rilevata: **%@**. Leggerai l'originale; il livello di traduzione viene generato.","ru":"Определён язык: **%@**. Вы читаете оригинал; слой перевода создаётся."],
        "detectedOther": ["en":"Detected language: **%@**. The book will be translated into the language you're learning — the original stays as the translation layer.","de":"Erkannte Sprache: **%@**. Das Buch wird in deine Lernsprache übersetzt — das Original bleibt als Übersetzungsebene erhalten.","sq":"Gjuha e zbuluar: **%@**. Libri do të përkthehet në gjuhën që mëson — origjinali mbetet si shtresa e përkthimit.","tr":"Algılanan dil: **%@**. Kitap öğrendiğin dile çevrilecek — orijinali çeviri katmanı olarak kalır.","es":"Idioma detectado: **%@**. El libro se traducirá al idioma que aprendes; el original queda como capa de traducción.","fr":"Langue détectée : **%@**. Le livre sera traduit dans la langue apprise — l'original reste la couche de traduction.","it":"Lingua rilevata: **%@**. Il libro sarà tradotto nella lingua che studi — l'originale resta come livello di traduzione.","ru":"Определён язык: **%@**. Книга будет переведена на изучаемый язык — оригинал останется слоем перевода."],
        "onDeviceNote": ["en":"Translation runs entirely on your iPhone. Nothing is uploaded. The first time, iOS may download the language pack.","de":"Die Übersetzung läuft komplett auf deinem iPhone. Nichts wird hochgeladen. Beim ersten Mal lädt iOS ggf. das Sprachpaket.","sq":"Përkthimi bëhet tërësisht në iPhone-in tënd. Asgjë nuk ngarkohet. Herën e parë iOS mund të shkarkojë paketën e gjuhës.","tr":"Çeviri tamamen iPhone'unda çalışır. Hiçbir şey yüklenmez. İlk seferde iOS dil paketini indirebilir.","es":"La traducción se hace por completo en tu iPhone. No se sube nada. La primera vez, iOS puede descargar el paquete de idioma.","fr":"La traduction se fait entièrement sur votre iPhone. Rien n'est envoyé. La première fois, iOS peut télécharger le pack linguistique.","it":"La traduzione avviene interamente sul tuo iPhone. Nulla viene caricato. La prima volta iOS potrebbe scaricare il pacchetto lingua.","ru":"Перевод выполняется полностью на вашем iPhone. Ничего не загружается. В первый раз iOS может скачать языковой пакет."],
        "longBookNote": ["en":"Long books can take a few minutes. Keep the screen on.","de":"Bei langen Büchern kann das ein paar Minuten dauern. Lass den Bildschirm an.","sq":"Librat e gjatë mund të marrin disa minuta. Mbaje ekranin ndezur.","tr":"Uzun kitaplar birkaç dakika sürebilir. Ekranı açık tut.","es":"Los libros largos pueden tardar unos minutos. Mantén la pantalla encendida.","fr":"Les longs livres peuvent prendre quelques minutes. Gardez l'écran allumé.","it":"I libri lunghi possono richiedere qualche minuto. Tieni lo schermo acceso.","ru":"Длинные книги могут занять несколько минут. Не гасите экран."],
        "translatingN": ["en":"Translating %@ sentences on device…","de":"Übersetze %@ Sätze auf dem Gerät…","sq":"Duke përkthyer %@ fjali në pajisje…","tr":"%@ cümle cihazda çevriliyor…","es":"Traduciendo %@ frases en el dispositivo…","fr":"Traduction de %@ phrases sur l'appareil…","it":"Traduzione di %@ frasi sul dispositivo…","ru":"Перевод %@ предложений на устройстве…"],
        "done": ["en":"Done","de":"Fertig","sq":"U krye","tr":"Bitti","es":"Listo","fr":"Terminé","it":"Fatto","ru":"Готово"],
        "translateAndAdd": ["en":"Translate and add","de":"Übersetzen und hinzufügen","sq":"Përkthe dhe shto","tr":"Çevir ve ekle","es":"Traducir y añadir","fr":"Traduire et ajouter","it":"Traduci e aggiungi","ru":"Перевести и добавить"],
        "close": ["en":"Close","de":"Schließen","sq":"Mbyll","tr":"Kapat","es":"Cerrar","fr":"Fermer","it":"Chiudi","ru":"Закрыть"],
        "importTitle": ["en":"Import a book","de":"Buch importieren","sq":"Importo një libër","tr":"Kitap içe aktar","es":"Importar un libro","fr":"Importer un livre","it":"Importa un libro","ru":"Импорт книги"],
        "importFailed": ["en":"Import failed","de":"Import fehlgeschlagen","sq":"Importimi dështoi","tr":"İçe aktarma başarısız","es":"Error al importar","fr":"Échec de l'importation","it":"Importazione fallita","ru":"Импорт не удался"],

        // book blurbs (titles stay in the original)
        "blurb_b1": ["en":"Jonas bakes at night. Milan can't sleep. A winter between four and five in the morning.","de":"Jonas backt nachts. Milan kann nicht schlafen. Ein Winter zwischen vier und fünf Uhr morgens.","sq":"Jonas piqet natën. Milani nuk fle dot. Një dimër mes orës katër dhe pesë të mëngjesit.","tr":"Jonas geceleri ekmek pişirir. Milan uyuyamaz. Sabahın dördü ile beşi arasında bir kış.","es":"Jonas hornea de noche. Milan no puede dormir. Un invierno entre las cuatro y las cinco de la madrugada.","fr":"Jonas boulange la nuit. Milan ne dort pas. Un hiver entre quatre et cinq heures du matin.","it":"Jonas inforna di notte. Milan non riesce a dormire. Un inverno tra le quattro e le cinque del mattino.","ru":"Йонас печёт по ночам. Милан не может спать. Зима между четырьмя и пятью утра."],
        "blurb_b2": ["en":"Theo inherits a pub. Samuel wants the space. Then the flood comes.","de":"Theo erbt eine Kneipe. Samuel will die Räume. Dann kommt das Hochwasser.","sq":"Theo trashëgon një lokal. Samueli i do hapësirat. Pastaj vjen përmbytja.","tr":"Theo bir meyhane miras alır. Samuel o mekânı istiyor. Sonra sel gelir.","es":"Theo hereda un bar. Samuel quiere el local. Entonces llega la inundación.","fr":"Theo hérite d'un bar. Samuel veut les locaux. Puis vient la crue.","it":"Theo eredita un pub. Samuel vuole quei locali. Poi arriva l'alluvione.","ru":"Тео получает в наследство паб. Самуэль хочет это помещение. А потом приходит наводнение."],
        "blurb_b3": ["en":"Anton comes back after six years. Yusuf never left. Three weeks in October.","de":"Anton kommt nach sechs Jahren zurück. Yusuf ist nie gegangen. Drei Wochen im Oktober.","sq":"Antoni kthehet pas gjashtë vjetësh. Jusufi nuk iku kurrë. Tri javë në tetor.","tr":"Anton altı yıl sonra döner. Yusuf hiç gitmedi. Ekimde üç hafta.","es":"Anton vuelve seis años después. Yusuf nunca se fue. Tres semanas de octubre.","fr":"Anton revient après six ans. Yusuf n'est jamais parti. Trois semaines en octobre.","it":"Anton torna dopo sei anni. Yusuf non è mai partito. Tre settimane di ottobre.","ru":"Антон возвращается через шесть лет. Юсуф никогда не уезжал. Три недели в октябре."],
        "blurb_b4": ["en":"A book from 1743, a year of work, and a man who closed a door.","de":"Ein Buch von 1743, ein Jahr Arbeit, und ein Mann, der eine Tür zugemacht hat.","sq":"Një libër i vitit 1743, një vit punë, dhe një burrë që mbylli një derë.","tr":"1743'ten bir kitap, bir yıllık emek ve bir kapıyı kapatmış bir adam.","es":"Un libro de 1743, un año de trabajo y un hombre que cerró una puerta.","fr":"Un livre de 1743, une année de travail, et un homme qui a fermé une porte.","it":"Un libro del 1743, un anno di lavoro, e un uomo che ha chiuso una porta.","ru":"Книга 1743 года, год работы и человек, закрывший одну дверь."],
        "buildingGlossary": ["en":"Building the word list…","de":"Wortliste wird erstellt…","sq":"Po ndërtohet lista e fjalëve…","tr":"Kelime listesi oluşturuluyor…","es":"Creando la lista de palabras…","fr":"Création de la liste de mots…","it":"Creazione dell'elenco di parole…","ru":"Создание списка слов…"],

        "replayOnboarding": ["en":"Show the setup again","de":"Einrichtung erneut anzeigen","sq":"Shfaq përsëri konfigurimin","tr":"Kurulumu tekrar göster","es":"Volver a mostrar la configuración","fr":"Revoir la configuration","it":"Mostra di nuovo la configurazione","ru":"Показать настройку снова"],
        "replayOnboardingHint": ["en":"Reopens the language and level screens. Your progress and books are kept.","de":"Öffnet die Sprach- und Niveau-Screens erneut. Fortschritt und Bücher bleiben erhalten.","sq":"Rihap ekranet e gjuhës dhe nivelit. Progresi dhe librat ruhen.","tr":"Dil ve seviye ekranlarını yeniden açar. İlerlemen ve kitapların korunur.","es":"Reabre las pantallas de idioma y nivel. Se conservan tu progreso y tus libros.","fr":"Réouvre les écrans de langue et de niveau. Votre progression et vos livres sont conservés.","it":"Riapre le schermate di lingua e livello. Progressi e libri vengono mantenuti.","ru":"Снова откроет экраны языка и уровня. Прогресс и книги сохранятся."],
        // onboarding
        "chooseTarget": ["en":"What do you want to learn?","de":"Was möchtest du lernen?","sq":"Çfarë doni të mësoni?","tr":"Ne öğrenmek istiyorsun?","es":"¿Qué quieres aprender?","fr":"Que voulez-vous apprendre ?","it":"Cosa vuoi imparare?","ru":"Что вы хотите изучать?"],
        "chooseLevel": ["en":"Where are you right now?","de":"Wo stehst du gerade?","sq":"Ku jeni tani?","tr":"Şu anda neredesin?","es":"¿En qué nivel estás?","fr":"Où en êtes-vous ?","it":"A che punto sei?","ru":"Какой у вас уровень?"],
        "levelHint": ["en":"This sets where you start. You can change it any time.","de":"Das bestimmt, wo du anfängst. Ändern kannst du es jederzeit.","sq":"Kjo përcakton se ku filloni. Mund ta ndryshoni në çdo kohë.","tr":"Bu, nereden başlayacağını belirler. İstediğin zaman değiştirebilirsin.","es":"Esto determina dónde empiezas. Puedes cambiarlo cuando quieras.","fr":"Cela détermine votre point de départ. Modifiable à tout moment.","it":"Determina da dove inizi. Puoi cambiarlo quando vuoi.","ru":"Это определяет, с чего вы начнёте. Можно изменить в любой момент."],
        "comingSoon": ["en":"Coming soon","de":"Bald verfügbar","sq":"Së shpejti","tr":"Yakında","es":"Próximamente","fr":"Bientôt","it":"Prossimamente","ru":"Скоро"],
        "start": ["en":"Start reading","de":"Los geht's","sq":"Fillo të lexosh","tr":"Okumaya başla","es":"Empezar a leer","fr":"Commencer","it":"Inizia a leggere","ru":"Начать читать"],
        "continueBtn": ["en":"Continue","de":"Weiter","sq":"Vazhdo","tr":"Devam","es":"Continuar","fr":"Continuer","it":"Continua","ru":"Далее"],
        "tagline": ["en":"Learn by reading stories you actually want to read.","de":"Lernen, indem du Geschichten liest, die du wirklich lesen willst.","sq":"Mëso duke lexuar histori që me të vërtetë dëshiron t'i lexosh.","tr":"Gerçekten okumak istediğin hikâyeleri okuyarak öğren.","es":"Aprende leyendo historias que realmente quieres leer.","fr":"Apprenez en lisant des histoires qui vous plaisent vraiment.","it":"Impara leggendo storie che vuoi davvero leggere.","ru":"Учитесь, читая истории, которые вам действительно интересны."],

        // tabs
        "tabLibrary": ["en":"Library","de":"Bibliothek","sq":"Biblioteka","tr":"Kitaplık","es":"Biblioteca","fr":"Bibliothèque","it":"Libreria","ru":"Библиотека"],
        "tabContinue": ["en":"Continue","de":"Weiterlesen","sq":"Vazhdo","tr":"Devam et","es":"Continuar","fr":"Reprendre","it":"Continua","ru":"Продолжить"],
        "tabMyBooks": ["en":"My books","de":"Meine Bücher","sq":"Librat e mi","tr":"Kitaplarım","es":"Mis libros","fr":"Mes livres","it":"I miei libri","ru":"Мои книги"],
        "tabSettings": ["en":"Settings","de":"Einstellungen","sq":"Cilësimet","tr":"Ayarlar","es":"Ajustes","fr":"Réglages","it":"Impostazioni","ru":"Настройки"],

        // library
        "genres": ["en":"Genres","de":"Genres","sq":"Zhanret","tr":"Türler","es":"Géneros","fr":"Genres","it":"Generi","ru":"Жанры"],
        "yourLevel": ["en":"Your level","de":"Dein Niveau","sq":"Niveli juaj","tr":"Seviyen","es":"Tu nivel","fr":"Votre niveau","it":"Il tuo livello","ru":"Ваш уровень"],
        "seriesCount": ["en":"series","de":"Reihen","sq":"seri","tr":"seri","es":"series","fr":"séries","it":"serie","ru":"серии"],
        "volumes": ["en":"volumes","de":"Bände","sq":"vëllime","tr":"cilt","es":"volúmenes","fr":"tomes","it":"volumi","ru":"тома"],
        "chapters": ["en":"chapters","de":"Kapitel","sq":"kapituj","tr":"bölüm","es":"capítulos","fr":"chapitres","it":"capitoli","ru":"главы"],
        "locked": ["en":"Locked","de":"Gesperrt","sq":"E kyçur","tr":"Kilitli","es":"Bloqueado","fr":"Verrouillé","it":"Bloccato","ru":"Заблокировано"],
        "easierOptional": ["en":"Easier · optional","de":"Leichter · optional","sq":"Më e lehtë · opsionale","tr":"Daha kolay · isteğe bağlı","es":"Más fácil · opcional","fr":"Plus facile · facultatif","it":"Più facile · opzionale","ru":"Легче · по желанию"],
        "completed": ["en":"Completed","de":"Abgeschlossen","sq":"E përfunduar","tr":"Tamamlandı","es":"Completado","fr":"Terminé","it":"Completato","ru":"Завершено"],
        "inProgress": ["en":"In progress","de":"In Arbeit","sq":"Në punë","tr":"Devam ediyor","es":"En curso","fr":"En cours","it":"In corso","ru":"В работе"],
        "lockedHint": ["en":"Opens at level %@. Finish the series before it, or change your level in Settings.","de":"Öffnet sich ab Niveau %@. Lies die Reihe davor zu Ende — oder ändere dein Niveau in den Einstellungen.","sq":"Hapet në nivelin %@. Përfundo serinë para saj, ose ndrysho nivelin te Cilësimet.","tr":"%@ seviyesinde açılır. Önceki seriyi bitir ya da Ayarlar'dan seviyeni değiştir.","es":"Se abre en el nivel %@. Termina la serie anterior o cambia tu nivel en Ajustes.","fr":"S'ouvre au niveau %@. Terminez la série précédente ou changez de niveau dans les Réglages.","it":"Si sblocca al livello %@. Finisci la serie precedente o cambia livello nelle Impostazioni.","ru":"Откроется на уровне %@. Завершите предыдущую серию или измените уровень в настройках."],
        "readInOrder": ["en":"Read this series in order. Words from Volume I come back in Volume II — that's the whole point.","de":"Diese Reihe wird der Reihe nach gelesen. Die Wörter aus Band I kommen in Band II wieder — genau davon lebt das Ganze.","sq":"Lexoje këtë seri me radhë. Fjalët nga Vëllimi I kthehen në Vëllimin II — kjo është e gjithë ideja.","tr":"Bu seriyi sırayla oku. I. ciltteki kelimeler II. ciltte geri gelir — bütün mesele bu.","es":"Lee esta serie en orden. Las palabras del Volumen I vuelven en el II: de eso se trata.","fr":"Lisez cette série dans l'ordre. Les mots du tome I reviennent au tome II — c'est tout l'intérêt.","it":"Leggi questa serie in ordine. Le parole del Volume I tornano nel II: è tutto qui.","ru":"Читайте серию по порядку. Слова из тома I возвращаются во втором — в этом весь смысл."],
        "notWritten": ["en":"Not written yet","de":"Noch nicht geschrieben","sq":"Ende e pashkruar","tr":"Henüz yazılmadı","es":"Aún no escrito","fr":"Pas encore écrit","it":"Non ancora scritto","ru":"Ещё не написано"],
        "resetSeries": ["en":"Reset progress for this series","de":"Fortschritt dieser Reihe zurücksetzen","sq":"Rivendos progresin e kësaj serie","tr":"Bu serinin ilerlemesini sıfırla","es":"Restablecer el progreso de esta serie","fr":"Réinitialiser la progression de cette série","it":"Azzera i progressi di questa serie","ru":"Сбросить прогресс этой серии"],
        "resetConfirm": ["en":"Reset progress?","de":"Fortschritt zurücksetzen?","sq":"Të rivendoset progresi?","tr":"İlerleme sıfırlansın mı?","es":"¿Restablecer el progreso?","fr":"Réinitialiser la progression ?","it":"Azzerare i progressi?","ru":"Сбросить прогресс?"],
        "cancel": ["en":"Cancel","de":"Abbrechen","sq":"Anulo","tr":"İptal","es":"Cancelar","fr":"Annuler","it":"Annulla","ru":"Отмена"],
        "reset": ["en":"Reset","de":"Zurücksetzen","sq":"Rivendos","tr":"Sıfırla","es":"Restablecer","fr":"Réinitialiser","it":"Azzera","ru":"Сбросить"],

        // continue
        "lastRead": ["en":"Last read","de":"Zuletzt gelesen","sq":"Lexuar së fundi","tr":"Son okunan","es":"Última lectura","fr":"Dernière lecture","it":"Ultima lettura","ru":"Последнее чтение"],
        "keepReading": ["en":"Keep reading","de":"Weiterlesen","sq":"Vazhdo leximin","tr":"Okumaya devam et","es":"Seguir leyendo","fr":"Continuer la lecture","it":"Continua a leggere","ru":"Продолжить чтение"],
        "nextChapter": ["en":"Next chapter","de":"Nächstes Kapitel","sq":"Kapitulli tjetër","tr":"Sonraki bölüm","es":"Capítulo siguiente","fr":"Chapitre suivant","it":"Capitolo successivo","ru":"Следующая глава"],
        "nothingRead": ["en":"Nothing read yet","de":"Noch nichts gelesen","sq":"Ende asgjë e lexuar","tr":"Henüz bir şey okunmadı","es":"Aún no has leído nada","fr":"Rien de lu pour l'instant","it":"Non hai ancora letto nulla","ru":"Пока ничего не прочитано"],
        "nothingReadHint": ["en":"Pick a genre in the library and start with Volume I.","de":"Wähle in der Bibliothek ein Genre und fang mit Band I an.","sq":"Zgjidh një zhanër në bibliotekë dhe fillo me Vëllimin I.","tr":"Kitaplıktan bir tür seç ve I. ciltle başla.","es":"Elige un género en la biblioteca y empieza por el Volumen I.","fr":"Choisissez un genre dans la bibliothèque et commencez par le tome I.","it":"Scegli un genere nella libreria e inizia dal Volume I.","ru":"Выберите жанр в библиотеке и начните с тома I."],
        "tip": ["en":"Tip","de":"Tipp","sq":"Këshillë","tr":"İpucu","es":"Consejo","fr":"Astuce","it":"Consiglio","ru":"Совет"],
        "tipBody": ["en":"Read each chapter twice. The second time you'll need the translation far less — that's where the learning happens.","de":"Lies jedes Kapitel zweimal. Beim zweiten Mal brauchst du die Übersetzung viel seltener — genau da passiert das Lernen.","sq":"Lexo çdo kapitull dy herë. Herën e dytë do të kesh shumë më pak nevojë për përkthimin — aty ndodh mësimi.","tr":"Her bölümü iki kez oku. İkincisinde çeviriye çok daha az ihtiyacın olacak — öğrenme tam orada oluyor.","es":"Lee cada capítulo dos veces. La segunda necesitarás mucho menos la traducción: ahí ocurre el aprendizaje.","fr":"Lisez chaque chapitre deux fois. La deuxième fois, vous aurez bien moins besoin de la traduction — c'est là que l'apprentissage se fait.","it":"Leggi ogni capitolo due volte. La seconda avrai molto meno bisogno della traduzione: è lì che si impara.","ru":"Читайте каждую главу дважды. Во второй раз перевод понадобится гораздо реже — именно тогда и происходит обучение."],

        // reader
        "chapter": ["en":"Chapter","de":"Kapitel","sq":"Kapitulli","tr":"Bölüm","es":"Capítulo","fr":"Chapitre","it":"Capitolo","ru":"Глава"],
        "readerHint": ["en":"Tap a word for its translation · tap the period for the whole sentence","de":"Tippe ein Wort für die Übersetzung · tippe den Punkt für den ganzen Satz","sq":"Prek një fjalë për përkthimin · prek pikën për të gjithë fjalinë","tr":"Çeviri için bir kelimeye dokun · tüm cümle için noktaya dokun","es":"Toca una palabra para su traducción · toca el punto para la frase entera","fr":"Touchez un mot pour sa traduction · touchez le point pour toute la phrase","it":"Tocca una parola per la traduzione · tocca il punto per l'intera frase","ru":"Нажмите на слово для перевода · нажмите на точку для всего предложения"],
        "back": ["en":"Back","de":"Zurück","sq":"Prapa","tr":"Geri","es":"Atrás","fr":"Retour","it":"Indietro","ru":"Назад"],
        "next": ["en":"Next","de":"Weiter","sq":"Tjetër","tr":"İleri","es":"Siguiente","fr":"Suivant","it":"Avanti","ru":"Далее"],
        "endOfVolume": ["en":"End of volume","de":"Ende des Bandes","sq":"Fundi i vëllimit","tr":"Cildin sonu","es":"Fin del volumen","fr":"Fin du tome","it":"Fine del volume","ru":"Конец тома"],
        "notInDictionary": ["en":"Not in the dictionary — tap the period at the end of the sentence for the full translation.","de":"Nicht im Wörterbuch — tippe den Punkt am Satzende für die ganze Übersetzung.","sq":"Nuk është në fjalor — prek pikën në fund të fjalisë për përkthimin e plotë.","tr":"Sözlükte yok — tam çeviri için cümlenin sonundaki noktaya dokun.","es":"No está en el diccionario: toca el punto final para la traducción completa.","fr":"Absent du dictionnaire — touchez le point final pour la traduction complète.","it":"Non è nel dizionario: tocca il punto finale per la traduzione completa.","ru":"Нет в словаре — нажмите точку в конце предложения для полного перевода."],
        "chooseChapter": ["en":"Choose chapter","de":"Kapitel wählen","sq":"Zgjidh kapitullin","tr":"Bölüm seç","es":"Elegir capítulo","fr":"Choisir un chapitre","it":"Scegli capitolo","ru":"Выбрать главу"],
        "readAloud": ["en":"Read chapter aloud","de":"Kapitel vorlesen","sq":"Lexo kapitullin me zë","tr":"Bölümü sesli oku","es":"Leer el capítulo en voz alta","fr":"Lire le chapitre à voix haute","it":"Leggi il capitolo ad alta voce","ru":"Читать главу вслух"],
        "textSize": ["en":"Text size","de":"Schriftgröße","sq":"Madhësia e tekstit","tr":"Yazı boyutu","es":"Tamaño del texto","fr":"Taille du texte","it":"Dimensione del testo","ru":"Размер текста"],
        "serifFont": ["en":"Serif font","de":"Serifenschrift","sq":"Shkronja me serif","tr":"Serifli yazı tipi","es":"Fuente con serifa","fr":"Police à empattement","it":"Carattere con grazie","ru":"Шрифт с засечками"],

        // settings
        "languages": ["en":"Languages","de":"Sprachen","sq":"Gjuhët","tr":"Diller","es":"Idiomas","fr":"Langues","it":"Lingue","ru":"Языки"],
        "learning": ["en":"Learning","de":"Lernsprache","sq":"Duke mësuar","tr":"Öğrenilen dil","es":"Aprendiendo","fr":"J'apprends","it":"Sto imparando","ru":"Изучаю"],
        "myLanguage": ["en":"My language","de":"Meine Sprache","sq":"Gjuha ime","tr":"Dilim","es":"Mi idioma","fr":"Ma langue","it":"La mia lingua","ru":"Мой язык"],
        "immersion": ["en":"Immersion mode","de":"Immersionsmodus","sq":"Modaliteti i zhytjes","tr":"Sürüklenme modu","es":"Modo inmersión","fr":"Mode immersion","it":"Modalità immersione","ru":"Режим погружения"],
        "immersionHint": ["en":"Shows the app's menus in the language you're learning instead of your own. Each language keeps its own progress and imported books.","de":"Zeigt die Menüs in der Lernsprache statt in deiner. Jede Sprache hat ihren eigenen Fortschritt und ihre eigenen importierten Bücher.","sq":"Shfaq menutë në gjuhën që po mëson në vend të gjuhës sate. Çdo gjuhë ruan progresin dhe librat e vet.","tr":"Menüleri kendi dilin yerine öğrendiğin dilde gösterir. Her dilin kendi ilerlemesi ve kitapları vardır.","es":"Muestra los menús en el idioma que aprendes en lugar del tuyo. Cada idioma guarda su propio progreso y libros.","fr":"Affiche les menus dans la langue apprise plutôt que la vôtre. Chaque langue garde sa progression et ses livres.","it":"Mostra i menu nella lingua che stai imparando invece che nella tua. Ogni lingua ha i suoi progressi e libri.","ru":"Показывает меню на изучаемом языке вместо вашего. У каждого языка свой прогресс и свои книги."],
        "levelHeader": ["en":"Your level","de":"Dein Niveau","sq":"Niveli juaj","tr":"Seviyen","es":"Tu nivel","fr":"Votre niveau","it":"Il tuo livello","ru":"Ваш уровень"],
        "levelFooter": ["en":"Decides which series are open. Rises automatically when you finish one.","de":"Bestimmt, welche Reihen offen sind. Steigt automatisch, wenn du eine Reihe abschließt.","sq":"Përcakton cilat seri janë të hapura. Rritet automatikisht kur përfundon një.","tr":"Hangi serilerin açık olduğunu belirler. Bir seriyi bitirince otomatik yükselir.","es":"Determina qué series están abiertas. Sube automáticamente al terminar una.","fr":"Détermine les séries ouvertes. Augmente automatiquement quand vous en terminez une.","it":"Determina quali serie sono aperte. Sale automaticamente quando ne finisci una.","ru":"Определяет, какие серии открыты. Повышается автоматически после завершения серии."],
        "readingHeader": ["en":"Reading","de":"Lesen","sq":"Leximi","tr":"Okuma","es":"Lectura","fr":"Lecture","it":"Lettura","ru":"Чтение"],
        "speech": ["en":"Speech","de":"Vorlesen","sq":"Të folurit","tr":"Seslendirme","es":"Voz","fr":"Lecture vocale","it":"Voce","ru":"Озвучивание"],
        "listen": ["en":"Listen","de":"Anhören","sq":"Dëgjo","tr":"Dinle","es":"Escuchar","fr":"Écouter","it":"Ascolta","ru":"Прослушать"],
        "sampleSentence": ["en":"A sample sentence for checking the size.","de":"Beispielsatz zum Testen der Größe.","sq":"Një fjali shembull për të kontrolluar madhësinë.","tr":"Boyutu denemek için örnek cümle.","es":"Una frase de ejemplo para comprobar el tamaño.","fr":"Une phrase d'exemple pour vérifier la taille.","it":"Una frase di esempio per controllare la dimensione.","ru":"Пример предложения для проверки размера."],

        // imports
        "noImports": ["en":"No books of your own","de":"Keine eigenen Bücher","sq":"Asnjë libër i yti","tr":"Kendi kitabın yok","es":"No tienes libros propios","fr":"Aucun livre à vous","it":"Nessun libro tuo","ru":"Своих книг нет"],
        "importHint": ["en":"Upload an EPUB in any language. If it isn't in the language you're learning, the app translates it for you — and the original becomes the translation layer.","de":"Lade ein EPUB hoch — egal in welcher Sprache. Ist es nicht in deiner Lernsprache, übersetzt die App es für dich, und das Original wird zur Übersetzungsebene.","sq":"Ngarko një EPUB në çdo gjuhë. Nëse s'është në gjuhën që mëson, aplikacioni e përkthen — dhe origjinali bëhet shtresa e përkthimit.","tr":"Herhangi bir dilde EPUB yükle. Öğrendiğin dilde değilse uygulama çevirir — orijinal de çeviri katmanı olur.","es":"Sube un EPUB en cualquier idioma. Si no está en el que aprendes, la app lo traduce y el original pasa a ser la capa de traducción.","fr":"Importez un EPUB dans n'importe quelle langue. S'il n'est pas dans celle que vous apprenez, l'app le traduit — l'original devient la couche de traduction.","it":"Carica un EPUB in qualsiasi lingua. Se non è nella lingua che studi, l'app lo traduce e l'originale diventa il livello di traduzione.","ru":"Загрузите EPUB на любом языке. Если он не на изучаемом языке, приложение переведёт его — а оригинал станет слоем перевода."],
        "chooseEpub": ["en":"Choose an EPUB","de":"EPUB auswählen","sq":"Zgjidh një EPUB","tr":"EPUB seç","es":"Elegir un EPUB","fr":"Choisir un EPUB","it":"Scegli un EPUB","ru":"Выбрать EPUB"],
        "machineTranslated": ["en":"machine-translated","de":"maschinell übersetzt","sq":"përkthyer me makinë","tr":"makine çevirisi","es":"traducción automática","fr":"traduction automatique","it":"tradotto automaticamente","ru":"машинный перевод"],
        "sentences": ["en":"sentences","de":"Sätze","sq":"fjali","tr":"cümle","es":"frases","fr":"phrases","it":"frasi","ru":"предложений"],
    ]
}
