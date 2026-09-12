import SwiftUI
import AppKit

struct IconSelectorView: View {
    let itemDescription: String
    let defaultIcon: String
    @Binding var customIcon: String

    @State private var showingPicker = false
    @State private var searchText = ""

    var body: some View {
        HStack(spacing: 8) {
            Text(itemDescription)

            Button {
                showingPicker = true
            } label: {
                iconButtonContent
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help("Browse SF Symbols")
            .popover(isPresented: $showingPicker, arrowEdge: .bottom) {
                SFSymbolPickerPopover(selection: $customIcon, searchText: $searchText) {
                    showingPicker = false
                }
            }

            if !customIcon.isEmpty {
                Button {
                    customIcon = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear custom icon")
            }

            Text(customIcon.isEmpty ? "Default" : customIcon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .onTapGesture {
                    showingPicker = true
                }
        }
    }

    @ViewBuilder
    private var iconButtonContent: some View {
        if !customIcon.isEmpty {
            Image(systemName: customIcon)
                .font(.system(size: 18))
        } else {
            Image(systemName: defaultIcon)
                .font(.system(size: 18))
        }
    }
}

struct SFSymbolPickerPopover: View {
    @Binding var selection: String
    @Binding var searchText: String
    let onSelect: () -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 44), spacing: 8)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search symbols...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.quaternary)

            Divider()

            // Symbol grid
            ScrollView {
                if searchText.isEmpty {
                    // Show categorized symbols
                    LazyVStack(alignment: .leading, spacing: 16, pinnedViews: .sectionHeaders) {
                        ForEach(SFSymbolCategories.allCategories, id: \.name) { category in
                            Section {
                                LazyVGrid(columns: columns, spacing: 8) {
                                    ForEach(category.symbols, id: \.self) { symbol in
                                        symbolButton(symbol)
                                    }
                                }
                            } header: {
                                Text(category.name)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)
                                    .background(.background)
                            }
                        }
                    }
                    .padding()
                } else {
                    // Show filtered symbols
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(filteredSymbols, id: \.self) { symbol in
                            symbolButton(symbol)
                        }
                    }
                    .padding()

                    if filteredSymbols.isEmpty {
                        Text("No symbols found")
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
            }
        }
        .frame(width: 320, height: 400)
    }

    private var filteredSymbols: [String] {
        let query = searchText.lowercased()
        return SFSymbolCategories.allSymbols.filter { $0.lowercased().contains(query) }
    }

    @ViewBuilder
    private func symbolButton(_ symbol: String) -> some View {
        Button {
            selection = symbol
            onSelect()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(selection == symbol ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help(symbol)
    }
}

// MARK: - SF Symbol Categories

struct SFSymbolCategory {
    let name: String
    let symbols: [String]
}

enum SFSymbolCategories {
    static let allCategories: [SFSymbolCategory] = [
        general,
        communication,
        weather,
        objects,
        devices,
        connectivity,
        transportation,
        nature,
        editing,
        textFormatting,
        media,
        keyboard,
        commerce,
        time,
        health,
        fitness,
        home,
        accessibility,
        shapes,
        arrows,
        indices,
        math,
        gaming,
        privacy
    ]

    static var allSymbols: [String] {
        allCategories.flatMap { $0.symbols }
    }

    static let general = SFSymbolCategory(name: "General", symbols: [
        "star", "star.fill", "star.circle", "star.circle.fill", "star.square", "star.square.fill",
        "star.leadinghalf.filled", "star.slash", "star.slash.fill",
        "heart", "heart.fill", "heart.circle", "heart.circle.fill", "heart.square", "heart.square.fill",
        "heart.slash", "heart.slash.fill", "heart.slash.circle", "heart.slash.circle.fill",
        "bolt", "bolt.fill", "bolt.circle", "bolt.circle.fill", "bolt.square", "bolt.square.fill",
        "bolt.slash", "bolt.slash.fill", "bolt.shield", "bolt.shield.fill",
        "bolt.trianglebadge.exclamationmark", "bolt.trianglebadge.exclamationmark.fill",
        "flag", "flag.fill", "flag.circle", "flag.circle.fill", "flag.square", "flag.square.fill",
        "flag.slash", "flag.slash.fill", "flag.badge.ellipsis", "flag.badge.ellipsis.fill",
        "flag.2.crossed", "flag.2.crossed.fill", "flag.checkered", "flag.checkered.2.crossed",
        "bell", "bell.fill", "bell.circle", "bell.circle.fill", "bell.square", "bell.square.fill",
        "bell.slash", "bell.slash.fill", "bell.badge", "bell.badge.fill",
        "bell.and.waves.left.and.right", "bell.and.waves.left.and.right.fill",
        "tag", "tag.fill", "tag.circle", "tag.circle.fill", "tag.square", "tag.square.fill",
        "tag.slash", "tag.slash.fill",
        "bolt.horizontal", "bolt.horizontal.fill", "bolt.horizontal.circle", "bolt.horizontal.circle.fill",
        "eye", "eye.fill", "eye.circle", "eye.circle.fill", "eye.square", "eye.square.fill",
        "eye.slash", "eye.slash.fill", "eye.slash.circle", "eye.slash.circle.fill",
        "eye.trianglebadge.exclamationmark", "eye.trianglebadge.exclamationmark.fill",
        "tshirt", "tshirt.fill", "shoe", "shoe.fill", "shoe.2", "shoe.2.fill",
        "comb", "comb.fill", "crown", "crown.fill", "trophy", "trophy.fill",
        "medal", "medal.fill", "rosette", "mustache", "mustache.fill",
        "mouth", "mouth.fill", "nose", "nose.fill", "brain", "brain.head.profile",
        "hand.raised", "hand.raised.fill", "hand.raised.circle", "hand.raised.circle.fill",
        "hand.raised.square", "hand.raised.square.fill", "hand.raised.slash", "hand.raised.slash.fill",
        "hand.thumbsup", "hand.thumbsup.fill", "hand.thumbsdown", "hand.thumbsdown.fill",
        "hand.point.up", "hand.point.up.fill", "hand.point.down", "hand.point.down.fill",
        "hand.point.left", "hand.point.left.fill", "hand.point.right", "hand.point.right.fill",
        "hand.wave", "hand.wave.fill", "hands.clap", "hands.clap.fill",
        "hands.sparkles", "hands.sparkles.fill",
        "sparkles", "sparkle", "sparkles.rectangle.stack", "sparkles.rectangle.stack.fill"
    ])

    static let communication = SFSymbolCategory(name: "Communication", symbols: [
        "message", "message.fill", "message.circle", "message.circle.fill",
        "message.badge", "message.badge.fill", "message.badge.filled.fill",
        "bubble.left", "bubble.left.fill", "bubble.right", "bubble.right.fill",
        "bubble.left.circle", "bubble.left.circle.fill", "bubble.right.circle", "bubble.right.circle.fill",
        "bubble.left.and.bubble.right", "bubble.left.and.bubble.right.fill",
        "bubble.middle.bottom", "bubble.middle.bottom.fill",
        "bubble.middle.top", "bubble.middle.top.fill",
        "phone", "phone.fill", "phone.circle", "phone.circle.fill",
        "phone.arrow.up.right", "phone.arrow.up.right.fill",
        "phone.arrow.down.left", "phone.arrow.down.left.fill",
        "phone.arrow.right", "phone.arrow.right.fill",
        "phone.badge.plus", "phone.badge.plus.fill",
        "phone.down", "phone.down.fill", "phone.down.circle", "phone.down.circle.fill",
        "envelope", "envelope.fill", "envelope.circle", "envelope.circle.fill",
        "envelope.open", "envelope.open.fill",
        "envelope.badge", "envelope.badge.fill",
        "envelope.arrow.triangle.branch", "envelope.arrow.triangle.branch.fill",
        "paperplane", "paperplane.fill", "paperplane.circle", "paperplane.circle.fill",
        "tray", "tray.fill", "tray.circle", "tray.circle.fill",
        "tray.full", "tray.full.fill", "tray.and.arrow.up", "tray.and.arrow.up.fill",
        "tray.and.arrow.down", "tray.and.arrow.down.fill", "tray.2", "tray.2.fill",
        "antenna.radiowaves.left.and.right", "antenna.radiowaves.left.and.right.circle",
        "antenna.radiowaves.left.and.right.circle.fill", "antenna.radiowaves.left.and.right.slash",
        "bubble.left.and.text.bubble.right", "bubble.left.and.text.bubble.right.fill",
        "captions.bubble", "captions.bubble.fill",
        "character.bubble", "character.bubble.fill",
        "text.bubble", "text.bubble.fill",
        "quote.bubble", "quote.bubble.fill", "quote.opening", "quote.closing"
    ])

    static let weather = SFSymbolCategory(name: "Weather", symbols: [
        "sun.min", "sun.min.fill", "sun.max", "sun.max.fill",
        "sun.max.circle", "sun.max.circle.fill",
        "sun.and.horizon", "sun.and.horizon.fill",
        "sun.dust", "sun.dust.fill", "sun.haze", "sun.haze.fill",
        "sunrise", "sunrise.fill", "sunset", "sunset.fill",
        "moon", "moon.fill", "moon.circle", "moon.circle.fill",
        "moon.stars", "moon.stars.fill", "moon.zzz", "moon.zzz.fill",
        "moon.haze", "moon.haze.fill",
        "sparkles", "moon.stars.circle", "moon.stars.circle.fill",
        "cloud", "cloud.fill", "cloud.circle", "cloud.circle.fill",
        "cloud.drizzle", "cloud.drizzle.fill",
        "cloud.rain", "cloud.rain.fill", "cloud.rain.circle", "cloud.rain.circle.fill",
        "cloud.heavyrain", "cloud.heavyrain.fill",
        "cloud.fog", "cloud.fog.fill",
        "cloud.hail", "cloud.hail.fill",
        "cloud.snow", "cloud.snow.fill", "cloud.snow.circle", "cloud.snow.circle.fill",
        "cloud.sleet", "cloud.sleet.fill",
        "cloud.bolt", "cloud.bolt.fill", "cloud.bolt.circle", "cloud.bolt.circle.fill",
        "cloud.bolt.rain", "cloud.bolt.rain.fill",
        "cloud.sun", "cloud.sun.fill", "cloud.sun.rain", "cloud.sun.rain.fill",
        "cloud.sun.bolt", "cloud.sun.bolt.fill",
        "cloud.moon", "cloud.moon.fill", "cloud.moon.rain", "cloud.moon.rain.fill",
        "cloud.moon.bolt", "cloud.moon.bolt.fill",
        "smoke", "smoke.fill", "smoke.circle", "smoke.circle.fill",
        "wind", "wind.circle", "wind.circle.fill", "wind.snow", "wind.snow.circle",
        "snowflake", "snowflake.circle", "snowflake.circle.fill", "snowflake.slash",
        "tornado", "tornado.circle", "tornado.circle.fill",
        "tropicalstorm", "tropicalstorm.circle", "tropicalstorm.circle.fill",
        "hurricane", "hurricane.circle", "hurricane.circle.fill",
        "thermometer.sun", "thermometer.sun.fill", "thermometer.snowflake",
        "thermometer.medium", "thermometer.low", "thermometer.high",
        "humidity", "humidity.fill",
        "aqi.low", "aqi.medium", "aqi.high",
        "water.waves", "water.waves.and.arrow.up", "water.waves.and.arrow.down",
        "drop", "drop.fill", "drop.circle", "drop.circle.fill",
        "drop.triangle", "drop.triangle.fill",
        "umbrella", "umbrella.fill", "umbrella.percent", "umbrella.percent.fill"
    ])

    static let objects = SFSymbolCategory(name: "Objects", symbols: [
        "folder", "folder.fill", "folder.circle", "folder.circle.fill",
        "folder.badge.plus", "folder.badge.minus", "folder.badge.questionmark",
        "folder.badge.gear", "folder.badge.person.crop",
        "doc", "doc.fill", "doc.circle", "doc.circle.fill",
        "doc.text", "doc.text.fill", "doc.text.magnifyingglass",
        "doc.on.doc", "doc.on.doc.fill", "doc.on.clipboard", "doc.on.clipboard.fill",
        "doc.badge.plus", "doc.badge.arrow.up", "doc.badge.ellipsis",
        "doc.badge.gearshape", "doc.badge.gearshape.fill",
        "clipboard", "clipboard.fill", "list.clipboard", "list.clipboard.fill",
        "note", "note.text", "note.text.badge.plus",
        "book", "book.fill", "book.circle", "book.circle.fill",
        "book.closed", "book.closed.fill", "book.closed.circle", "book.closed.circle.fill",
        "books.vertical", "books.vertical.fill", "books.vertical.circle", "books.vertical.circle.fill",
        "book.and.wrench", "book.and.wrench.fill",
        "menucard", "menucard.fill", "magazine", "magazine.fill",
        "newspaper", "newspaper.fill", "newspaper.circle", "newspaper.circle.fill",
        "bookmark", "bookmark.fill", "bookmark.circle", "bookmark.circle.fill",
        "bookmark.square", "bookmark.square.fill", "bookmark.slash", "bookmark.slash.fill",
        "pencil", "pencil.circle", "pencil.circle.fill", "pencil.slash",
        "pencil.and.outline", "pencil.and.scribble", "pencil.line",
        "eraser", "eraser.fill", "eraser.line.dashed", "eraser.line.dashed.fill",
        "trash", "trash.fill", "trash.circle", "trash.circle.fill",
        "trash.square", "trash.square.fill", "trash.slash", "trash.slash.fill",
        "archivebox", "archivebox.fill", "archivebox.circle", "archivebox.circle.fill",
        "bin.xmark", "bin.xmark.fill",
        "externaldrive", "externaldrive.fill",
        "externaldrive.badge.plus", "externaldrive.badge.minus",
        "externaldrive.badge.checkmark", "externaldrive.badge.xmark",
        "internaldrive", "internaldrive.fill",
        "opticaldiscdrive", "opticaldiscdrive.fill",
        "paperclip", "paperclip.circle", "paperclip.circle.fill",
        "paperclip.badge.ellipsis", "link", "link.circle", "link.circle.fill",
        "link.badge.plus", "pin", "pin.fill", "pin.circle", "pin.circle.fill",
        "pin.square", "pin.square.fill", "pin.slash", "pin.slash.fill",
        "map", "map.fill", "map.circle", "map.circle.fill",
        "mappin", "mappin.circle", "mappin.circle.fill", "mappin.square", "mappin.square.fill",
        "mappin.slash", "mappin.slash.circle", "mappin.slash.circle.fill",
        "mappin.and.ellipse",
        "graduationcap", "graduationcap.fill", "graduationcap.circle", "graduationcap.circle.fill"
    ])

    static let devices = SFSymbolCategory(name: "Devices", symbols: [
        "desktopcomputer", "pc", "macmini", "macmini.fill", "macpro.gen1", "macpro.gen2", "macpro.gen3", "macpro.gen3.fill",
        "macstudio", "macstudio.fill",
        "laptopcomputer", "laptopcomputer.and.iphone", "laptopcomputer.and.arrow.down",
        "display", "display.2", "display.trianglebadge.exclamationmark",
        "macbook", "macbook.and.iphone", "macbook.and.ipad", "macbook.gen2",
        "server.rack", "xserve",
        "iphone", "iphone.gen1", "iphone.gen2", "iphone.gen3",
        "iphone.circle", "iphone.circle.fill",
        "iphone.badge.play", "iphone.radiowaves.left.and.right",
        "iphone.slash", "iphone.slash.circle", "iphone.slash.circle.fill",
        "ipad", "ipad.gen1", "ipad.gen2",
        "ipad.badge.play", "ipad.and.iphone", "ipad.and.arrow.down",
        "applewatch", "applewatch.watchface", "applewatch.radiowaves.left.and.right",
        "applewatch.side.right", "applewatch.slash",
        "airpods", "airpodspro", "airpodspro.chargingcase.wireless", "airpodsmax",
        "homepod", "homepod.fill", "homepod.2", "homepod.2.fill", "homepodmini", "homepodmini.fill",
        "hifispeaker", "hifispeaker.fill", "hifispeaker.2", "hifispeaker.2.fill",
        "appletv", "appletv.fill", "mediastick",
        "keyboard", "keyboard.fill", "keyboard.badge.ellipsis", "keyboard.badge.ellipsis.fill",
        "keyboard.chevron.compact.down", "keyboard.chevron.compact.left",
        "keyboard.onehanded.left", "keyboard.onehanded.right",
        "computermouse", "computermouse.fill", "magicmouse", "magicmouse.fill",
        "trackpad.horizontal.only", "trackpad.and.hand",
        "printer", "printer.fill", "printer.filled.and.paper", "printer.dotmatrix", "printer.dotmatrix.fill",
        "scanner", "scanner.fill",
        "faxmachine", "faxmachine.fill",
        "camera", "camera.fill", "camera.circle", "camera.circle.fill",
        "camera.shutter.button", "camera.shutter.button.fill",
        "camera.badge.ellipsis", "camera.on.rectangle", "camera.on.rectangle.fill",
        "video", "video.fill", "video.circle", "video.circle.fill",
        "video.square", "video.square.fill", "video.slash", "video.slash.fill",
        "video.badge.plus", "video.badge.checkmark",
        "tv", "tv.fill", "tv.circle", "tv.circle.fill",
        "tv.inset.filled", "tv.and.hifispeaker.fill", "tv.and.mediabox",
        "4k.tv", "4k.tv.fill", "music.note.tv", "music.note.tv.fill",
        "play.tv", "play.tv.fill", "photo.tv",
        "gamecontroller", "gamecontroller.fill"
    ])

    static let connectivity = SFSymbolCategory(name: "Connectivity", symbols: [
        "wifi", "wifi.circle", "wifi.circle.fill", "wifi.square", "wifi.square.fill",
        "wifi.slash", "wifi.exclamationmark",
        "wifi.router", "wifi.router.fill",
        "network", "network.slash", "network.badge.shield.half.filled",
        "globe", "globe.americas", "globe.americas.fill", "globe.europe.africa", "globe.europe.africa.fill",
        "globe.asia.australia", "globe.asia.australia.fill",
        "globe.central.south.asia", "globe.central.south.asia.fill",
        "globe.badge.chevron.backward",
        "network", "network.slash",
        "personalhotspot", "personalhotspot.circle", "personalhotspot.circle.fill",
        "antenna.radiowaves.left.and.right",
        "antenna.radiowaves.left.and.right.circle", "antenna.radiowaves.left.and.right.circle.fill",
        "antenna.radiowaves.left.and.right.slash",
        "dot.radiowaves.left.and.right", "dot.radiowaves.right", "dot.radiowaves.up.forward",
        "wave.3.left", "wave.3.left.circle", "wave.3.left.circle.fill",
        "wave.3.right", "wave.3.right.circle", "wave.3.right.circle.fill",
        "wave.3.forward", "wave.3.forward.circle", "wave.3.forward.circle.fill",
        "wave.3.backward", "wave.3.backward.circle", "wave.3.backward.circle.fill",
        "cellularbars", "chart.bar.fill",
        "shareplay", "shareplay.slash", "person.wave.2", "person.wave.2.fill",
        "point.3.connected.trianglepath.dotted", "point.3.filled.connected.trianglepath.dotted"
    ])

    static let transportation = SFSymbolCategory(name: "Transportation", symbols: [
        "car", "car.fill", "car.circle", "car.circle.fill",
        "car.2", "car.2.fill", "car.side", "car.side.fill",
        "bolt.car", "bolt.car.fill", "bolt.car.circle", "bolt.car.circle.fill",
        "car.top.door.front.left.and.front.right.open",
        "suv.side", "suv.side.fill",
        "bus", "bus.fill", "bus.doubledecker", "bus.doubledecker.fill",
        "tram", "tram.fill", "tram.circle", "tram.circle.fill",
        "cablecar", "cablecar.fill",
        "lightrail", "lightrail.fill",
        "train.side.front.car", "train.side.middle.car", "train.side.rear.car",
        "airplane", "airplane.circle", "airplane.circle.fill",
        "airplane.departure", "airplane.arrival",
        "ferry", "ferry.fill",
        "sailboat", "sailboat.fill", "sailboat.circle", "sailboat.circle.fill",
        "fuelpump", "fuelpump.fill", "fuelpump.circle", "fuelpump.circle.fill",
        "ev.charger", "ev.charger.fill",
        "ev.plug.ac.type.1", "ev.plug.ac.type.2", "ev.plug.dc.ccs1", "ev.plug.dc.ccs2",
        "bicycle", "bicycle.circle", "bicycle.circle.fill",
        "scooter", "skateboard", "skateboard.fill",
        "stroller", "stroller.fill",
        "figure.walk", "figure.walk.circle", "figure.walk.circle.fill",
        "figure.walk.motion", "figure.walk.arrival", "figure.walk.departure",
        "figure.run", "figure.run.circle", "figure.run.circle.fill",
        "figure.roll", "figure.roll.runningpace",
        "figure.and.child.holdinghands", "figure.2.and.child.holdinghands",
        "person", "person.fill", "person.circle", "person.circle.fill",
        "person.2", "person.2.fill", "person.2.circle", "person.2.circle.fill",
        "person.3", "person.3.fill", "person.3.sequence", "person.3.sequence.fill",
        "person.crop.circle", "person.crop.circle.fill",
        "person.crop.square", "person.crop.square.fill",
        "person.crop.rectangle", "person.crop.rectangle.fill",
        "person.badge.plus", "person.badge.minus",
        "person.badge.key", "person.badge.key.fill",
        "person.badge.shield.checkmark", "person.badge.shield.checkmark.fill"
    ])

    static let nature = SFSymbolCategory(name: "Nature", symbols: [
        "leaf", "leaf.fill", "leaf.circle", "leaf.circle.fill",
        "leaf.arrow.triangle.circlepath",
        "tree", "tree.fill", "tree.circle", "tree.circle.fill",
        "mountain.2", "mountain.2.fill", "mountain.2.circle", "mountain.2.circle.fill",
        "globe.americas", "globe.europe.africa", "globe.asia.australia",
        "flame", "flame.fill", "flame.circle", "flame.circle.fill",
        "bolt", "bolt.fill", "bolt.circle", "bolt.circle.fill",
        "drop", "drop.fill", "drop.circle", "drop.circle.fill",
        "drop.degreesign", "drop.degreesign.fill",
        "drop.halffull", "humidity", "humidity.fill",
        "atom", "fossil.shell", "fossil.shell.fill",
        "pawprint", "pawprint.fill", "pawprint.circle", "pawprint.circle.fill",
        "ant", "ant.fill", "ant.circle", "ant.circle.fill",
        "ladybug", "ladybug.fill", "ladybug.circle", "ladybug.circle.fill",
        "bird", "bird.fill", "bird.circle", "bird.circle.fill",
        "fish", "fish.fill", "fish.circle", "fish.circle.fill",
        "hare", "hare.fill", "hare.circle", "hare.circle.fill",
        "tortoise", "tortoise.fill", "tortoise.circle", "tortoise.circle.fill",
        "dog", "dog.fill", "dog.circle", "dog.circle.fill",
        "cat", "cat.fill", "cat.circle", "cat.circle.fill",
        "lizard", "lizard.fill", "lizard.circle", "lizard.circle.fill",
        "carrot", "carrot.fill",
        "leaf.arrow.triangle.circlepath",
        "camera.macro", "camera.macro.circle", "camera.macro.circle.fill",
        "moonphase.new.moon", "moonphase.waxing.crescent", "moonphase.first.quarter",
        "moonphase.waxing.gibbous", "moonphase.full.moon", "moonphase.waning.gibbous",
        "moonphase.last.quarter", "moonphase.waning.crescent"
    ])

    static let editing = SFSymbolCategory(name: "Editing", symbols: [
        "pencil", "pencil.circle", "pencil.circle.fill",
        "pencil.slash", "pencil.line", "pencil.and.outline",
        "square.and.pencil", "square.and.pencil.circle", "square.and.pencil.circle.fill",
        "rectangle.and.pencil.and.ellipsis",
        "highlighter", "lasso", "lasso.and.sparkles",
        "scribble", "scribble.variable",
        "applepencil", "applepencil.and.scribble",
        "scissors", "scissors.circle", "scissors.circle.fill",
        "scissors.badge.ellipsis",
        "wand.and.rays", "wand.and.rays.inverse",
        "wand.and.stars", "wand.and.stars.inverse",
        "crop", "crop.rotate",
        "dial.min", "dial.min.fill", "dial.max", "dial.max.fill",
        "dial.medium", "dial.medium.fill", "dial.high", "dial.high.fill", "dial.low", "dial.low.fill",
        "gyroscope",
        "paintbrush", "paintbrush.fill",
        "paintbrush.pointed", "paintbrush.pointed.fill",
        "paintpalette", "paintpalette.fill",
        "eyedropper", "eyedropper.halffull", "eyedropper.full",
        "rotate.left", "rotate.left.fill", "rotate.right", "rotate.right.fill",
        "perspective",
        "skew",
        "flip.horizontal", "flip.horizontal.fill",
        "aspectratio", "aspectratio.fill",
        "camera.filters", "photo.stack", "photo.stack.fill",
        "square.on.square.squareshape.controlhandles",
        "slider.horizontal.3", "slider.horizontal.2.square",
        "slider.horizontal.2.square.badge.arrow.down", "slider.horizontal.2.gobackward",
        "slider.horizontal.below.rectangle", "slider.horizontal.below.square.filled.and.square",
        "slider.vertical.3", "checkerboard.rectangle",
        "loupe",
        "circle.lefthalf.filled", "circle.righthalf.filled",
        "circle.tophalf.filled", "circle.bottomhalf.filled"
    ])

    static let textFormatting = SFSymbolCategory(name: "Text Formatting", symbols: [
        "textformat", "textformat.size", "textformat.size.smaller", "textformat.size.larger",
        "textformat.superscript", "textformat.subscript",
        "bold", "italic", "underline", "strikethrough",
        "shadow", "abc",
        "textformat.abc", "textformat.abc.dottedunderline",
        "textformat.alt", "textformat.12", "textformat.123",
        "text.cursor", "character.cursor.ibeam",
        "list.bullet", "list.bullet.circle", "list.bullet.circle.fill",
        "list.bullet.indent", "list.bullet.rectangle", "list.bullet.rectangle.fill",
        "list.number", "list.dash", "list.dash.header.rectangle",
        "list.bullet.clipboard", "list.bullet.clipboard.fill",
        "list.clipboard", "list.clipboard.fill",
        "text.alignleft", "text.aligncenter", "text.alignright", "text.justify",
        "text.justify.left", "text.justify.leading", "text.justify.right", "text.justify.trailing",
        "text.word.spacing",
        "increase.indent", "decrease.indent",
        "increase.quotelevel", "decrease.quotelevel",
        "text.quote",
        "text.redaction",
        "line.3.horizontal", "line.3.horizontal.decrease", "line.3.horizontal.decrease.circle",
        "line.3.horizontal.circle", "line.3.horizontal.circle.fill",
        "line.2.horizontal.decrease.circle", "line.2.horizontal.decrease.circle.fill",
        "character", "character.book.closed", "character.book.closed.fill",
        "a.magnify", "textformat.subscript", "textformat.superscript",
        "text.insert", "text.append", "text.badge.plus", "text.badge.minus",
        "text.badge.checkmark", "text.badge.xmark", "text.badge.star",
        "paragraphsign",
        "character.textbox",
        "info", "info.circle", "info.circle.fill", "info.square", "info.square.fill"
    ])

    static let media = SFSymbolCategory(name: "Media", symbols: [
        "play", "play.fill", "play.circle", "play.circle.fill",
        "play.square", "play.square.fill", "play.rectangle", "play.rectangle.fill",
        "play.slash", "play.slash.fill",
        "pause", "pause.fill", "pause.circle", "pause.circle.fill",
        "pause.rectangle", "pause.rectangle.fill",
        "stop", "stop.fill", "stop.circle", "stop.circle.fill",
        "playpause", "playpause.fill", "playpause.circle", "playpause.circle.fill",
        "record.circle", "record.circle.fill",
        "backward", "backward.fill", "backward.circle", "backward.circle.fill",
        "forward", "forward.fill", "forward.circle", "forward.circle.fill",
        "backward.end", "backward.end.fill", "backward.end.circle", "backward.end.circle.fill",
        "forward.end", "forward.end.fill", "forward.end.circle", "forward.end.circle.fill",
        "backward.frame", "backward.frame.fill", "forward.frame", "forward.frame.fill",
        "shuffle", "shuffle.circle", "shuffle.circle.fill",
        "repeat", "repeat.circle", "repeat.circle.fill", "repeat.1", "repeat.1.circle", "repeat.1.circle.fill",
        "infinity", "infinity.circle", "infinity.circle.fill",
        "speaker", "speaker.fill", "speaker.circle", "speaker.circle.fill",
        "speaker.square", "speaker.square.fill",
        "speaker.wave.1", "speaker.wave.1.fill",
        "speaker.wave.2", "speaker.wave.2.fill", "speaker.wave.2.circle", "speaker.wave.2.circle.fill",
        "speaker.wave.3", "speaker.wave.3.fill",
        "speaker.slash", "speaker.slash.fill", "speaker.slash.circle", "speaker.slash.circle.fill",
        "speaker.plus", "speaker.plus.fill", "speaker.minus", "speaker.minus.fill",
        "speaker.zzz", "speaker.zzz.fill",
        "music.note", "music.note.list", "music.quarternote.3",
        "music.mic", "music.mic.circle", "music.mic.circle.fill",
        "goforward", "goforward.5", "goforward.10", "goforward.15", "goforward.30", "goforward.45", "goforward.60",
        "gobackward", "gobackward.5", "gobackward.10", "gobackward.15", "gobackward.30", "gobackward.45", "gobackward.60",
        "swift",
        "headphones", "headphones.circle", "headphones.circle.fill",
        "radio", "radio.fill",
        "tuningfork",
        "pianokeys", "pianokeys.inverse",
        "guitars", "guitars.fill",
        "mic", "mic.fill", "mic.circle", "mic.circle.fill",
        "mic.square", "mic.square.fill", "mic.slash", "mic.slash.fill",
        "mic.badge.plus", "mic.badge.xmark",
        "waveform", "waveform.circle", "waveform.circle.fill",
        "waveform.path", "waveform.path.badge.plus", "waveform.path.badge.minus",
        "photo", "photo.fill", "photo.circle", "photo.circle.fill",
        "photo.on.rectangle", "photo.on.rectangle.angled",
        "rectangle.on.rectangle", "rectangle.on.rectangle.circle", "rectangle.on.rectangle.circle.fill",
        "photo.stack", "photo.stack.fill",
        "photo.badge.plus", "photo.badge.plus.fill",
        "photo.badge.arrow.down", "photo.badge.arrow.down.fill",
        "photo.badge.checkmark", "photo.badge.checkmark.fill",
        "livephoto", "livephoto.slash", "livephoto.badge.automatic",
        "video", "video.fill", "video.circle", "video.circle.fill",
        "video.square", "video.square.fill", "video.slash", "video.slash.fill",
        "video.badge.plus", "video.badge.checkmark", "video.badge.ellipsis",
        "film", "film.fill", "film.circle", "film.circle.fill", "film.stack", "film.stack.fill"
    ])

    static let keyboard = SFSymbolCategory(name: "Keyboard", symbols: [
        "command", "command.circle", "command.circle.fill", "command.square", "command.square.fill",
        "option", "alt",
        "control", "shift", "shift.fill",
        "capslock", "capslock.fill",
        "power", "power.circle", "power.circle.fill", "power.dotted",
        "globe", "globe.badge.chevron.backward",
        "delete.left", "delete.left.fill", "delete.right", "delete.right.fill",
        "delete.backward", "delete.backward.fill", "delete.forward", "delete.forward.fill",
        "clear", "clear.fill",
        "escape",
        "return", "return.left", "return.right",
        "projective", "eject", "eject.fill", "eject.circle", "eject.circle.fill",
        "fn",
        "space",
        "chevron.up.square", "chevron.down.square", "chevron.left.square", "chevron.right.square",
        "arrow.up.square", "arrow.down.square", "arrow.left.square", "arrow.right.square",
        "arrowtriangle.up.square", "arrowtriangle.down.square",
        "arrowtriangle.left.square", "arrowtriangle.right.square"
    ])

    static let commerce = SFSymbolCategory(name: "Commerce", symbols: [
        "cart", "cart.fill", "cart.circle", "cart.circle.fill",
        "cart.badge.plus", "cart.badge.minus", "cart.badge.questionmark",
        "bag", "bag.fill", "bag.circle", "bag.circle.fill",
        "bag.badge.plus", "bag.badge.minus", "bag.badge.questionmark",
        "basket", "basket.fill",
        "creditcard", "creditcard.fill", "creditcard.circle", "creditcard.circle.fill",
        "creditcard.and.123", "creditcard.trianglebadge.exclamationmark",
        "giftcard", "giftcard.fill",
        "wallet.pass", "wallet.pass.fill",
        "dollarsign", "dollarsign.circle", "dollarsign.circle.fill",
        "dollarsign.square", "dollarsign.square.fill",
        "dollarsign.arrow.circlepath",
        "eurosign", "eurosign.circle", "eurosign.circle.fill",
        "eurosign.square", "eurosign.square.fill",
        "yensign", "yensign.circle", "yensign.circle.fill",
        "yensign.square", "yensign.square.fill",
        "sterlingsign", "sterlingsign.circle", "sterlingsign.circle.fill",
        "sterlingsign.square", "sterlingsign.square.fill",
        "francsign", "francsign.circle", "francsign.circle.fill",
        "florinsign", "florinsign.circle", "florinsign.circle.fill",
        "turkishlirasign", "turkishlirasign.circle", "turkishlirasign.circle.fill",
        "rupeesign", "rupeesign.circle", "rupeesign.circle.fill",
        "pesetasign", "pesetasign.circle", "pesetasign.circle.fill",
        "pesosign", "pesosign.circle", "pesosign.circle.fill",
        "kipsign", "kipsign.circle", "kipsign.circle.fill",
        "wonsign", "wonsign.circle", "wonsign.circle.fill",
        "lirasign", "lirasign.circle", "lirasign.circle.fill",
        "australsign", "australsign.circle", "australsign.circle.fill",
        "hryvniasign", "hryvniasign.circle", "hryvniasign.circle.fill",
        "nairasign", "nairasign.circle", "nairasign.circle.fill",
        "guaranisign", "guaranisign.circle", "guaranisign.circle.fill",
        "coloncurrencysign", "coloncurrencysign.circle", "coloncurrencysign.circle.fill",
        "cedisign", "cedisign.circle", "cedisign.circle.fill",
        "cruzeirosign", "cruzeirosign.circle", "cruzeirosign.circle.fill",
        "tugriksign", "tugriksign.circle", "tugriksign.circle.fill",
        "millsign", "millsign.circle", "millsign.circle.fill",
        "shekelsign", "shekelsign.circle", "shekelsign.circle.fill",
        "manatsign", "manatsign.circle", "manatsign.circle.fill",
        "rupeesign", "rupeesign.circle", "rupeesign.circle.fill",
        "bahtsign", "bahtsign.circle", "bahtsign.circle.fill",
        "larisign", "larisign.circle", "larisign.circle.fill",
        "bitcoinsign", "bitcoinsign.circle", "bitcoinsign.circle.fill",
        "centsign", "centsign.circle", "centsign.circle.fill",
        "gift", "gift.fill", "gift.circle", "gift.circle.fill",
        "storefront", "storefront.fill", "storefront.circle", "storefront.circle.fill",
        "barcode", "barcode.viewfinder", "qrcode", "qrcode.viewfinder"
    ])

    static let time = SFSymbolCategory(name: "Time", symbols: [
        "clock", "clock.fill", "clock.circle", "clock.circle.fill",
        "clock.badge", "clock.badge.fill", "clock.badge.checkmark", "clock.badge.checkmark.fill",
        "clock.badge.exclamationmark", "clock.badge.exclamationmark.fill",
        "clock.badge.questionmark", "clock.badge.questionmark.fill",
        "clock.arrow.circlepath", "clock.arrow.2.circlepath",
        "deskclock", "deskclock.fill",
        "alarm", "alarm.fill", "alarm.waves.left.and.right", "alarm.waves.left.and.right.fill",
        "stopwatch", "stopwatch.fill",
        "timer", "timer.circle", "timer.circle.fill", "timer.square",
        "hourglass", "hourglass.circle", "hourglass.circle.fill",
        "hourglass.badge.plus",
        "hourglass.bottomhalf.filled", "hourglass.tophalf.filled",
        "calendar", "calendar.circle", "calendar.circle.fill",
        "calendar.badge.plus", "calendar.badge.minus", "calendar.badge.clock",
        "calendar.badge.exclamationmark",
        "calendar.day.timeline.left", "calendar.day.timeline.right",
        "calendar.day.timeline.leading", "calendar.day.timeline.trailing"
    ])

    static let health = SFSymbolCategory(name: "Health", symbols: [
        "heart", "heart.fill", "heart.circle", "heart.circle.fill",
        "heart.square", "heart.square.fill",
        "heart.slash", "heart.slash.fill", "heart.slash.circle", "heart.slash.circle.fill",
        "heart.text.square", "heart.text.square.fill",
        "bolt.heart", "bolt.heart.fill",
        "cross", "cross.fill", "cross.circle", "cross.circle.fill",
        "cross.vial", "cross.vial.fill",
        "staroflife", "staroflife.fill", "staroflife.circle", "staroflife.circle.fill",
        "staroflife.shield", "staroflife.shield.fill",
        "pills", "pills.fill", "pills.circle", "pills.circle.fill",
        "pill", "pill.fill", "pill.circle", "pill.circle.fill",
        "capsule", "capsule.fill", "capsule.portrait", "capsule.portrait.fill",
        "cross.case", "cross.case.fill", "cross.case.circle", "cross.case.circle.fill",
        "medical.thermometer", "medical.thermometer.fill",
        "syringe", "syringe.fill",
        "ivfluid.bag", "ivfluid.bag.fill",
        "bandage", "bandage.fill",
        "stethoscope", "stethoscope.circle", "stethoscope.circle.fill",
        "facemask", "facemask.fill",
        "brain", "brain.head.profile", "brain.filled.head.profile",
        "lungs", "lungs.fill",
        "allergens", "allergens.fill",
        "waveform.path.ecg", "waveform.path.ecg.rectangle", "waveform.path.ecg.rectangle.fill",
        "heart.rectangle", "heart.rectangle.fill",
        "waveform.ecg", "electrocardiogram",
        "bolt.heart", "bolt.heart.fill"
    ])

    static let shapes = SFSymbolCategory(name: "Shapes", symbols: [
        "circle", "circle.fill", "circle.slash", "circle.slash.fill",
        "circle.lefthalf.filled", "circle.righthalf.filled",
        "circle.tophalf.filled", "circle.bottomhalf.filled",
        "circle.inset.filled", "circle.dashed", "circle.dotted",
        "smallcircle.filled.circle", "smallcircle.filled.circle.fill",
        "circle.circle", "circle.circle.fill",
        "oval", "oval.fill", "oval.portrait", "oval.portrait.fill",
        "capsule", "capsule.fill", "capsule.portrait", "capsule.portrait.fill",
        "square", "square.fill", "square.slash", "square.slash.fill",
        "square.lefthalf.filled", "square.righthalf.filled",
        "square.tophalf.filled", "square.bottomhalf.filled",
        "square.inset.filled", "square.dashed", "square.dotted",
        "square.split.1x2", "square.split.1x2.fill",
        "square.split.2x1", "square.split.2x1.fill",
        "square.split.2x2", "square.split.2x2.fill",
        "square.split.diagonal.2x2", "square.split.diagonal.2x2.fill",
        "square.split.bottomrightquarter", "square.split.bottomrightquarter.fill",
        "rectangle", "rectangle.fill", "rectangle.slash", "rectangle.slash.fill",
        "rectangle.portrait", "rectangle.portrait.fill",
        "rectangle.lefthalf.filled", "rectangle.righthalf.filled",
        "rectangle.tophalf.filled", "rectangle.bottomhalf.filled",
        "rectangle.lefthalf.inset.filled", "rectangle.righthalf.inset.filled",
        "rectangle.leadinghalf.inset.filled", "rectangle.trailinghalf.inset.filled",
        "rectangle.tophalf.inset.filled", "rectangle.bottomhalf.inset.filled",
        "rectangle.inset.filled", "rectangle.dashed", "rectangle.dotted",
        "rectangle.split.3x1", "rectangle.split.3x1.fill",
        "rectangle.split.3x3", "rectangle.split.3x3.fill",
        "triangle", "triangle.fill", "triangle.lefthalf.filled", "triangle.righthalf.filled",
        "triangle.tophalf.filled", "triangle.bottomhalf.filled",
        "diamond", "diamond.fill", "diamond.lefthalf.filled", "diamond.righthalf.filled",
        "diamond.tophalf.filled", "diamond.bottomhalf.filled",
        "octagon", "octagon.fill", "octagon.lefthalf.filled", "octagon.righthalf.filled",
        "hexagon", "hexagon.fill", "hexagon.lefthalf.filled", "hexagon.righthalf.filled",
        "pentagon", "pentagon.fill", "pentagon.lefthalf.filled", "pentagon.righthalf.filled",
        "seal", "seal.fill", "star", "star.fill", "star.leadinghalf.filled",
        "shield", "shield.fill", "shield.lefthalf.filled", "shield.righthalf.filled",
        "shield.slash", "shield.slash.fill",
        "rhombus", "rhombus.fill",
        "app", "app.fill", "app.badge", "app.badge.fill",
        "app.dashed", "appclip",
        "rectangle.grid.1x2", "rectangle.grid.1x2.fill",
        "rectangle.grid.2x2", "rectangle.grid.2x2.fill",
        "square.grid.2x2", "square.grid.2x2.fill",
        "square.grid.3x2", "square.grid.3x2.fill",
        "square.grid.3x3", "square.grid.3x3.fill",
        "square.grid.4x3.fill", "square.grid.3x1.below.line.grid.1x2",
        "rectangle.grid.3x2", "rectangle.grid.3x2.fill",
        "squareshape", "squareshape.fill", "squareshape.dashed.squareshape",
        "dot.squareshape", "dot.squareshape.fill"
    ])

    static let arrows = SFSymbolCategory(name: "Arrows", symbols: [
        "arrow.up", "arrow.up.circle", "arrow.up.circle.fill", "arrow.up.square", "arrow.up.square.fill",
        "arrow.down", "arrow.down.circle", "arrow.down.circle.fill", "arrow.down.square", "arrow.down.square.fill",
        "arrow.left", "arrow.left.circle", "arrow.left.circle.fill", "arrow.left.square", "arrow.left.square.fill",
        "arrow.right", "arrow.right.circle", "arrow.right.circle.fill", "arrow.right.square", "arrow.right.square.fill",
        "arrow.up.left", "arrow.up.left.circle", "arrow.up.left.circle.fill",
        "arrow.up.right", "arrow.up.right.circle", "arrow.up.right.circle.fill",
        "arrow.down.left", "arrow.down.left.circle", "arrow.down.left.circle.fill",
        "arrow.down.right", "arrow.down.right.circle", "arrow.down.right.circle.fill",
        "arrow.up.left.and.arrow.down.right", "arrow.up.left.and.arrow.down.right.circle",
        "arrow.up.right.and.arrow.down.left", "arrow.up.right.and.arrow.down.left.circle",
        "arrow.left.and.right", "arrow.left.and.right.circle", "arrow.left.and.right.circle.fill",
        "arrow.up.and.down", "arrow.up.and.down.circle", "arrow.up.and.down.circle.fill",
        "arrow.up.to.line", "arrow.up.to.line.circle", "arrow.up.to.line.circle.fill",
        "arrow.down.to.line", "arrow.down.to.line.circle", "arrow.down.to.line.circle.fill",
        "arrow.left.to.line", "arrow.left.to.line.circle", "arrow.left.to.line.circle.fill",
        "arrow.right.to.line", "arrow.right.to.line.circle", "arrow.right.to.line.circle.fill",
        "arrow.uturn.left", "arrow.uturn.left.circle", "arrow.uturn.left.circle.fill",
        "arrow.uturn.right", "arrow.uturn.right.circle", "arrow.uturn.right.circle.fill",
        "arrow.uturn.up", "arrow.uturn.up.circle", "arrow.uturn.up.circle.fill",
        "arrow.uturn.down", "arrow.uturn.down.circle", "arrow.uturn.down.circle.fill",
        "arrow.uturn.backward", "arrow.uturn.backward.circle", "arrow.uturn.backward.circle.fill",
        "arrow.uturn.forward", "arrow.uturn.forward.circle", "arrow.uturn.forward.circle.fill",
        "arrow.clockwise", "arrow.clockwise.circle", "arrow.clockwise.circle.fill",
        "arrow.counterclockwise", "arrow.counterclockwise.circle", "arrow.counterclockwise.circle.fill",
        "arrow.2.squarepath", "arrow.triangle.2.circlepath", "arrow.triangle.2.circlepath.circle",
        "arrow.triangle.capsulepath",
        "arrow.3.trianglepath",
        "arrowshape.left", "arrowshape.left.fill", "arrowshape.right", "arrowshape.right.fill",
        "arrowshape.up", "arrowshape.up.fill", "arrowshape.down", "arrowshape.down.fill",
        "arrowshape.turn.up.left", "arrowshape.turn.up.left.fill",
        "arrowshape.turn.up.right", "arrowshape.turn.up.right.fill",
        "arrowshape.turn.up.left.2", "arrowshape.turn.up.left.2.fill",
        "arrowshape.turn.up.backward", "arrowshape.turn.up.backward.fill",
        "arrowshape.turn.up.forward", "arrowshape.turn.up.forward.fill",
        "arrowshape.zigzag.right", "arrowshape.zigzag.right.fill",
        "arrowshape.zigzag.forward", "arrowshape.zigzag.forward.fill",
        "arrowshape.bounce.right", "arrowshape.bounce.right.fill",
        "arrowshape.bounce.forward", "arrowshape.bounce.forward.fill",
        "arrow.up.and.down.and.arrow.left.and.right",
        "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left",
        "arrow.left.arrow.right", "arrow.left.arrow.right.circle", "arrow.left.arrow.right.circle.fill",
        "arrow.up.arrow.down", "arrow.up.arrow.down.circle", "arrow.up.arrow.down.circle.fill",
        "chevron.up", "chevron.up.circle", "chevron.up.circle.fill", "chevron.up.square", "chevron.up.square.fill",
        "chevron.down", "chevron.down.circle", "chevron.down.circle.fill", "chevron.down.square", "chevron.down.square.fill",
        "chevron.left", "chevron.left.circle", "chevron.left.circle.fill", "chevron.left.square", "chevron.left.square.fill",
        "chevron.right", "chevron.right.circle", "chevron.right.circle.fill", "chevron.right.square", "chevron.right.square.fill",
        "chevron.left.2", "chevron.right.2", "chevron.up.2", "chevron.down.2",
        "chevron.compact.up", "chevron.compact.down", "chevron.compact.left", "chevron.compact.right"
    ])

    static let indices = SFSymbolCategory(name: "Indices", symbols: [
        "0.circle", "0.circle.fill", "0.square", "0.square.fill",
        "1.circle", "1.circle.fill", "1.square", "1.square.fill",
        "2.circle", "2.circle.fill", "2.square", "2.square.fill",
        "3.circle", "3.circle.fill", "3.square", "3.square.fill",
        "4.circle", "4.circle.fill", "4.square", "4.square.fill",
        "5.circle", "5.circle.fill", "5.square", "5.square.fill",
        "6.circle", "6.circle.fill", "6.square", "6.square.fill",
        "7.circle", "7.circle.fill", "7.square", "7.square.fill",
        "8.circle", "8.circle.fill", "8.square", "8.square.fill",
        "9.circle", "9.circle.fill", "9.square", "9.square.fill",
        "00.circle", "00.circle.fill", "00.square", "00.square.fill",
        "01.circle", "01.circle.fill", "01.square", "01.square.fill",
        "02.circle", "02.circle.fill", "02.square", "02.square.fill",
        "03.circle", "03.circle.fill", "03.square", "03.square.fill",
        "04.circle", "04.circle.fill", "04.square", "04.square.fill",
        "05.circle", "05.circle.fill", "05.square", "05.square.fill",
        "06.circle", "06.circle.fill", "06.square", "06.square.fill",
        "07.circle", "07.circle.fill", "07.square", "07.square.fill",
        "08.circle", "08.circle.fill", "08.square", "08.square.fill",
        "09.circle", "09.circle.fill", "09.square", "09.square.fill",
        "10.circle", "10.circle.fill", "10.square", "10.square.fill",
        "a.circle", "a.circle.fill", "a.square", "a.square.fill",
        "b.circle", "b.circle.fill", "b.square", "b.square.fill",
        "c.circle", "c.circle.fill", "c.square", "c.square.fill",
        "d.circle", "d.circle.fill", "d.square", "d.square.fill",
        "e.circle", "e.circle.fill", "e.square", "e.square.fill",
        "f.circle", "f.circle.fill", "f.square", "f.square.fill",
        "g.circle", "g.circle.fill", "g.square", "g.square.fill",
        "h.circle", "h.circle.fill", "h.square", "h.square.fill",
        "i.circle", "i.circle.fill", "i.square", "i.square.fill",
        "j.circle", "j.circle.fill", "j.square", "j.square.fill",
        "k.circle", "k.circle.fill", "k.square", "k.square.fill",
        "l.circle", "l.circle.fill", "l.square", "l.square.fill",
        "m.circle", "m.circle.fill", "m.square", "m.square.fill",
        "n.circle", "n.circle.fill", "n.square", "n.square.fill",
        "o.circle", "o.circle.fill", "o.square", "o.square.fill",
        "p.circle", "p.circle.fill", "p.square", "p.square.fill",
        "q.circle", "q.circle.fill", "q.square", "q.square.fill",
        "r.circle", "r.circle.fill", "r.square", "r.square.fill",
        "s.circle", "s.circle.fill", "s.square", "s.square.fill",
        "t.circle", "t.circle.fill", "t.square", "t.square.fill",
        "u.circle", "u.circle.fill", "u.square", "u.square.fill",
        "v.circle", "v.circle.fill", "v.square", "v.square.fill",
        "w.circle", "w.circle.fill", "w.square", "w.square.fill",
        "x.circle", "x.circle.fill", "x.square", "x.square.fill",
        "y.circle", "y.circle.fill", "y.square", "y.square.fill",
        "z.circle", "z.circle.fill", "z.square", "z.square.fill"
    ])

    static let math = SFSymbolCategory(name: "Math", symbols: [
        "plus", "plus.circle", "plus.circle.fill", "plus.square", "plus.square.fill",
        "plus.rectangle", "plus.rectangle.fill", "plus.diamond", "plus.diamond.fill",
        "minus", "minus.circle", "minus.circle.fill", "minus.square", "minus.square.fill",
        "minus.rectangle", "minus.rectangle.fill", "minus.diamond", "minus.diamond.fill",
        "plus.forwardslash.minus", "minus.forwardslash.plus",
        "plusminus", "plusminus.circle", "plusminus.circle.fill",
        "multiply", "multiply.circle", "multiply.circle.fill", "multiply.square", "multiply.square.fill",
        "divide", "divide.circle", "divide.circle.fill", "divide.square", "divide.square.fill",
        "equal", "equal.circle", "equal.circle.fill", "equal.square", "equal.square.fill",
        "lessthan", "lessthan.circle", "lessthan.circle.fill", "lessthan.square", "lessthan.square.fill",
        "greaterthan", "greaterthan.circle", "greaterthan.circle.fill", "greaterthan.square", "greaterthan.square.fill",
        "lessthan.or.equal", "greaterthan.or.equal",
        "number", "number.circle", "number.circle.fill", "number.square", "number.square.fill",
        "x.squareroot",
        "percent", "sum", "function",
        "curlybraces", "curlybraces.square", "curlybraces.square.fill",
        "parentheses", "angle", "brackets.curly",
        "bracket.fill", "chevron.left.forwardslash.chevron.right"
    ])

    static let gaming = SFSymbolCategory(name: "Gaming", symbols: [
        "gamecontroller", "gamecontroller.fill",
        "dpad", "dpad.fill",
        "dpad.left.filled", "dpad.right.filled", "dpad.up.filled", "dpad.down.filled",
        "l.joystick", "l.joystick.fill", "r.joystick", "r.joystick.fill",
        "l.joystick.press.down", "l.joystick.press.down.fill",
        "r.joystick.press.down", "r.joystick.press.down.fill",
        "l.joystick.tilt.left", "l.joystick.tilt.left.fill",
        "l.joystick.tilt.right", "l.joystick.tilt.right.fill",
        "l.joystick.tilt.up", "l.joystick.tilt.up.fill",
        "l.joystick.tilt.down", "l.joystick.tilt.down.fill",
        "r.joystick.tilt.left", "r.joystick.tilt.left.fill",
        "r.joystick.tilt.right", "r.joystick.tilt.right.fill",
        "r.joystick.tilt.up", "r.joystick.tilt.up.fill",
        "r.joystick.tilt.down", "r.joystick.tilt.down.fill",
        "l1.button.roundedbottom.horizontal", "l1.button.roundedbottom.horizontal.fill",
        "l2.button.roundedtop.horizontal", "l2.button.roundedtop.horizontal.fill",
        "r1.button.roundedbottom.horizontal", "r1.button.roundedbottom.horizontal.fill",
        "r2.button.roundedtop.horizontal", "r2.button.roundedtop.horizontal.fill",
        "lb.button.roundedbottom.horizontal", "lb.button.roundedbottom.horizontal.fill",
        "rb.button.roundedbottom.horizontal", "rb.button.roundedbottom.horizontal.fill",
        "lt.button.roundedtop.horizontal", "lt.button.roundedtop.horizontal.fill",
        "rt.button.roundedtop.horizontal", "rt.button.roundedtop.horizontal.fill",
        "zl.button.roundedtop.horizontal", "zl.button.roundedtop.horizontal.fill",
        "zr.button.roundedtop.horizontal", "zr.button.roundedtop.horizontal.fill",
        "circle.grid.cross", "circle.grid.cross.fill",
        "circle.grid.cross.left.filled", "circle.grid.cross.right.filled",
        "circle.grid.cross.up.filled", "circle.grid.cross.down.filled",
        "puzzlepiece", "puzzlepiece.fill",
        "puzzlepiece.extension", "puzzlepiece.extension.fill",
        "die.face.1", "die.face.1.fill", "die.face.2", "die.face.2.fill",
        "die.face.3", "die.face.3.fill", "die.face.4", "die.face.4.fill",
        "die.face.5", "die.face.5.fill", "die.face.6", "die.face.6.fill",
        "trophy", "trophy.fill", "trophy.circle", "trophy.circle.fill",
        "medal", "medal.fill",
        "arcade.stick", "arcade.stick.console", "arcade.stick.console.fill"
    ])

    static let privacy = SFSymbolCategory(name: "Privacy & Security", symbols: [
        "lock", "lock.fill", "lock.circle", "lock.circle.fill",
        "lock.square", "lock.square.fill", "lock.square.stack", "lock.square.stack.fill",
        "lock.rectangle", "lock.rectangle.fill", "lock.rectangle.stack", "lock.rectangle.stack.fill",
        "lock.open", "lock.open.fill",
        "lock.open.rotation", "lock.open.rotation.variant.fill", "lock.rotation", "lock.rotation.fill",
        "lock.slash", "lock.slash.fill",
        "lock.trianglebadge.exclamationmark", "lock.trianglebadge.exclamationmark.fill",
        "lock.shield", "lock.shield.fill",
        "lock.display", "lock.laptopcomputer", "lock.iphone", "lock.ipad", "lock.applewatch",
        "key", "key.fill", "key.horizontal", "key.horizontal.fill",
        "key.viewfinder", "key.radiowaves.forward", "key.radiowaves.forward.fill",
        "key.icloud", "key.icloud.fill",
        "faceid", "touchid", "opticid", "opticid.fill",
        "person.badge.key", "person.badge.key.fill",
        "hand.raised", "hand.raised.fill", "hand.raised.circle", "hand.raised.circle.fill",
        "hand.raised.square", "hand.raised.square.fill",
        "hand.raised.slash", "hand.raised.slash.fill",
        "hand.raised.fingers.spread", "hand.raised.fingers.spread.fill",
        "shield", "shield.fill", "shield.lefthalf.filled", "shield.righthalf.filled",
        "shield.slash", "shield.slash.fill",
        "checkmark.shield", "checkmark.shield.fill",
        "xmark.shield", "xmark.shield.fill",
        "exclamationmark.shield", "exclamationmark.shield.fill",
        "shield.lefthalf.filled.slash",
        "shield.lefthalf.filled.badge.checkmark",
        "shield.lefthalf.filled.trianglebadge.exclamationmark",
        "person.badge.shield.checkmark", "person.badge.shield.checkmark.fill",
        "eye.slash", "eye.slash.fill", "eye.slash.circle", "eye.slash.circle.fill",
        "figure.stand.line.dotted.figure.stand",
        "person.crop.square.filled.and.at.rectangle",
        "person.crop.square.filled.and.at.rectangle.fill"
    ])

    static let fitness = SFSymbolCategory(name: "Fitness", symbols: [
        "figure.walk", "figure.walk.circle", "figure.walk.circle.fill",
        "figure.walk.motion", "figure.walk.arrival", "figure.walk.departure",
        "figure.run", "figure.run.circle", "figure.run.circle.fill",
        "figure.run.square.stack", "figure.run.square.stack.fill",
        "figure.roll", "figure.roll.runningpace",
        "figure.hiking", "figure.outdoor.cycle", "figure.indoor.cycle",
        "figure.cooldown", "figure.core.training", "figure.cross.training",
        "figure.dance", "figure.disc.sports", "figure.elliptical",
        "figure.equestrian.sports", "figure.fencing", "figure.fishing",
        "figure.flexibility", "figure.golf", "figure.gymnastics",
        "figure.hand.cycling", "figure.handball", "figure.highintensity.intervaltraining",
        "figure.jumprope", "figure.kickboxing", "figure.lacrosse",
        "figure.martial.arts", "figure.mind.and.body", "figure.mixed.cardio",
        "figure.open.water.swim", "figure.pickleball", "figure.pilates",
        "figure.play", "figure.pool.swim", "figure.racquetball",
        "figure.rolling", "figure.rower", "figure.rugby",
        "figure.sailing", "figure.skating", "figure.skiing.crosscountry",
        "figure.skiing.downhill", "figure.snowboarding", "figure.soccer",
        "figure.socialdance", "figure.softball", "figure.squash",
        "figure.stair.stepper", "figure.stairs", "figure.step.training",
        "figure.strengthtraining.functional", "figure.strengthtraining.traditional",
        "figure.surfing", "figure.table.tennis", "figure.taichi",
        "figure.tennis", "figure.track.and.field", "figure.volleyball",
        "figure.water.fitness", "figure.waterpolo", "figure.wave",
        "figure.wrestling", "figure.yoga",
        "sportscourt", "sportscourt.fill", "sportscourt.circle", "sportscourt.circle.fill",
        "baseball", "baseball.fill", "baseball.diamond.bases",
        "basketball", "basketball.fill", "basketball.circle", "basketball.circle.fill",
        "football", "football.fill", "football.circle", "football.circle.fill",
        "tennis.racket", "tennis.racket.circle", "tennis.racket.circle.fill",
        "soccerball", "soccerball.circle", "soccerball.circle.fill", "soccerball.inverse",
        "cricket.ball", "cricket.ball.fill", "cricket.ball.circle", "cricket.ball.circle.fill",
        "tennisball", "tennisball.fill", "tennisball.circle", "tennisball.circle.fill",
        "volleyball", "volleyball.fill", "volleyball.circle", "volleyball.circle.fill",
        "dumbbell", "dumbbell.fill",
        "scalemass", "scalemass.fill",
        "heart.circle", "heart.circle.fill",
        "bolt.heart", "bolt.heart.fill"
    ])

    static let home = SFSymbolCategory(name: "Home", symbols: [
        "house", "house.fill", "house.circle", "house.circle.fill",
        "house.lodge", "house.lodge.fill", "house.lodge.circle", "house.lodge.circle.fill",
        "building", "building.fill", "building.2", "building.2.fill",
        "building.2.crop.circle", "building.2.crop.circle.fill",
        "building.columns", "building.columns.fill", "building.columns.circle", "building.columns.circle.fill",
        "lightbulb", "lightbulb.fill", "lightbulb.circle", "lightbulb.circle.fill",
        "lightbulb.led", "lightbulb.led.fill",
        "lightbulb.min", "lightbulb.min.fill", "lightbulb.max", "lightbulb.max.fill",
        "lightbulb.slash", "lightbulb.slash.fill",
        "lamp.desk", "lamp.desk.fill", "lamp.floor", "lamp.floor.fill",
        "lamp.table", "lamp.table.fill", "lamp.ceiling", "lamp.ceiling.fill",
        "chandelier", "chandelier.fill",
        "light.recessed", "light.recessed.fill", "light.recessed.3", "light.recessed.3.fill",
        "light.panel", "light.panel.fill", "light.strip.2", "light.strip.2.fill",
        "fan", "fan.fill", "fan.ceiling", "fan.ceiling.fill",
        "fan.floor", "fan.floor.fill",
        "air.purifier", "air.purifier.fill",
        "dehumidifier", "dehumidifier.fill", "humidifier", "humidifier.fill",
        "heater.vertical", "heater.vertical.fill",
        "air.conditioner.horizontal", "air.conditioner.horizontal.fill",
        "air.conditioner.vertical", "air.conditioner.vertical.fill",
        "spigot", "spigot.fill", "shower", "shower.fill", "shower.sidejet", "shower.sidejet.fill",
        "shower.handheld", "shower.handheld.fill", "bathtub", "bathtub.fill",
        "toilet", "toilet.fill", "sink", "sink.fill",
        "washer", "washer.fill", "dryer", "dryer.fill", "dishwasher", "dishwasher.fill",
        "refrigerator", "refrigerator.fill", "oven", "oven.fill",
        "microwave", "microwave.fill", "cooktop", "cooktop.fill",
        "stove", "stove.fill", "fireplace", "fireplace.fill",
        "sofa", "sofa.fill", "chair.lounge", "chair.lounge.fill",
        "chair", "chair.fill", "bed.double", "bed.double.fill",
        "bed.double.circle", "bed.double.circle.fill",
        "cabinet", "cabinet.fill", "table.furniture", "table.furniture.fill",
        "wardrobe", "wardrobe.fill", "dresser", "dresser.fill",
        "tent", "tent.fill", "tent.2", "tent.2.fill",
        "door.left.hand.open", "door.left.hand.closed",
        "door.right.hand.open", "door.right.hand.closed",
        "door.sliding.left.hand.open", "door.sliding.left.hand.closed",
        "door.sliding.right.hand.open", "door.sliding.right.hand.closed",
        "door.garage.open", "door.garage.closed", "door.garage.double.bay.open", "door.garage.double.bay.closed",
        "window.vertical.open", "window.vertical.closed",
        "window.horizontal", "window.horizontal.closed",
        "window.ceiling", "window.ceiling.closed",
        "window.casement", "window.casement.closed",
        "window.awning", "window.awning.closed",
        "blinds.vertical.open", "blinds.vertical.closed",
        "blinds.horizontal.open", "blinds.horizontal.closed",
        "curtains.open", "curtains.closed",
        "roller.shade.open", "roller.shade.closed",
        "sensor", "sensor.fill", "sensor.tag.radiowaves.forward", "sensor.tag.radiowaves.forward.fill",
        "sprinkler", "sprinkler.fill", "sprinkler.and.droplets", "sprinkler.and.droplets.fill",
        "videoprojector", "videoprojector.fill"
    ])

    static let accessibility = SFSymbolCategory(name: "Accessibility", symbols: [
        "accessibility", "accessibility.fill",
        "figure.stand", "figure.stand.dress",
        "figure.wave", "figure.wave.circle", "figure.wave.circle.fill",
        "figure.fall", "figure.fall.circle", "figure.fall.circle.fill",
        "figure.arms.open",
        "figure.2.arms.open", "figure.2.and.child.holdinghands",
        "figure.and.child.holdinghands", "figure.child", "figure.child.circle", "figure.child.circle.fill",
        "ear", "ear.fill", "ear.badge.checkmark", "ear.trianglebadge.exclamationmark",
        "ear.and.waveform",
        "hearingdevice.ear", "hearingdevice.ear.fill",
        "hearingdevice.and.signal.meter", "hearingdevice.and.signal.meter.fill",
        "hand.point.up.braille", "hand.point.up.braille.fill",
        "ellipsis.bubble", "ellipsis.bubble.fill",
        "text.bubble", "text.bubble.fill",
        "eye", "eye.fill", "eye.slash", "eye.slash.fill",
        "eye.circle", "eye.circle.fill",
        "eyeglasses", "eyeglasses.slash",
        "person.crop.circle.badge.questionmark", "person.crop.circle.badge.questionmark.fill",
        "brain", "brain.head.profile", "brain.filled.head.profile",
        "brain.fill",
        "figure.seated.side.automatic", "figure.seated.side.air.distribution.upper",
        "figure.seated.side.air.distribution.lower", "figure.seated.side.air.distribution.middle",
        "figure.seated.side.air.distribution.middle.and.lower",
        "figure.seated.side.air.windshield", "figure.seated.side.airbag.on",
        "figure.seated.side.airbag.off", "figure.seated.side.windshield.front.and.heat.waves",
        "keyboard", "keyboard.fill",
        "keyboard.badge.ellipsis", "keyboard.badge.ellipsis.fill",
        "character.cursor.ibeam",
        "text.magnifyingglass",
        "character.magnify",
        "text.viewfinder"
    ])
}

#Preview {
    struct PreviewWrapper: View {
        @State private var customIcon = "star.fill"
        @State private var noIcon = ""

        var body: some View {
            VStack(spacing: 20) {
                IconSelectorView(
                    itemDescription: "Menu Bar Icon:",
                    defaultIcon: "bolt.fill",
                    customIcon: $noIcon
                )

                Divider()

                IconSelectorView(
                    itemDescription: "Custom Icon:",
                    defaultIcon: "folder.fill",
                    customIcon: $customIcon
                )
            }
            .padding()
            .frame(width: 400)
        }
    }

    return PreviewWrapper()
}
