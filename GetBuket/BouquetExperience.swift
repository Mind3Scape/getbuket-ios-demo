import SwiftUI
import UIKit

struct BouquetExperience: View {
    private enum ScenePhase { case choosing, assembling, ready }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: ScenePhase = .choosing
    @State private var position = Bouquet.collection.count
    @State private var drag: CGFloat = 0
    @State private var reveal = false
    @State private var flowersFlying = false
    @State private var step = 0
    @State private var bag: [Bouquet] = []
    @State private var favorites: Set<String> = []
    @State private var showBag = false
    @State private var showDemoControls = false
    @State private var demoRunning = false
    @State private var assemblyTask: Task<Void, Never>?
    @State private var demoTask: Task<Void, Never>?
    private let spacing: CGFloat = 137
    private var bouquet: Bouquet { Bouquet.collection[positiveModulo(position, Bouquet.collection.count)] }
    private let steps = ["Выбираем самые красивые", "Собираем с любовью", "Последний штрих"]

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            ZStack(alignment: .top) {
                StudioBackground()
                studio(width: width, height: height)
                header.padding(.top, max(geo.safeAreaInsets.top, 59) + 12).padding(.horizontal, 27)

                if phase == .choosing {
                    chooser(width: width, bottom: max(geo.safeAreaInsets.bottom, 31))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(3)
                }
                if phase == .assembling {
                    assemblingCaption
                        .position(x: width / 2, y: height - geo.safeAreaInsets.bottom - 48)
                        .transition(.opacity)
                }
                if phase == .ready {
                    readyControls(bottom: max(geo.safeAreaInsets.bottom, 31))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(width: width, height: height)
            .clipped()
        }
        .ignoresSafeArea()
        .foregroundStyle(Color.ink)
        .sheet(isPresented: $showBag) { bagSheet }
        .confirmationDialog("Для записи экрана", isPresented: $showDemoControls, titleVisibility: .visible) {
            Button("Запустить демонстрацию") { runDemo() }
            Button("Сначала") { reset() }
        }
        .task {
            if ProcessInfo.processInfo.arguments.contains("--record-demo") {
                try? await Task.sleep(for: .seconds(2))
                runDemo()
            }
        }
        .onDisappear { assemblyTask?.cancel(); demoTask?.cancel() }
    }

    private var header: some View {
        HStack {
            Button { if phase != .choosing { reset() } } label: {
                Image("brand-logo").resizable().scaledToFit().frame(width: 154, height: 24)
            }
            .accessibilityLabel("GetBuket. Вернуться к выбору")
            .onLongPressGesture(minimumDuration: 0.7) { showDemoControls = true }
            Spacer()
            Button { showBag = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bag").font(.system(size: 19, weight: .regular)).frame(width: 43, height: 43)
                        .foregroundStyle(Color.brandPurple)
                        .modifier(BrandGlass(shape: Circle()))
                    if !bag.isEmpty {
                        Text("\(bag.count)").font(.system(size: 10, weight: .semibold)).foregroundStyle(.white)
                            .frame(width: 17, height: 17).background(Color.brandPurple, in: Circle()).offset(x: 2, y: -1)
                    }
                }
            }.accessibilityLabel("Корзина, \(bag.count) букетов")
        }
    }

    private func studio(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            if phase == .choosing {
                VStack(spacing: 21) {
                    Text("ИСКУССТВО РАДОВАТЬ")
                        .font(.system(size: 9, weight: .semibold)).tracking(2.8)
                        .foregroundStyle(Color.brandPurple)
                    VStack(spacing: 0) {
                        Text("Цветы вместо").foregroundStyle(Color.ink)
                        Text("тысячи слов.").foregroundStyle(Color.brandPurple)
                    }
                    .font(.system(size: 41, weight: .semibold)).tracking(-1.8)
                    .multilineTextAlignment(.center)
                    Text("Для особенного человека.\nИли просто для себя.")
                        .font(.system(size: 14)).lineSpacing(5)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.ink.opacity(0.48))
                }.position(x: width / 2, y: height * 0.307)
                    .transition(.opacity.combined(with: .offset(y: -15)))
            }

            if phase != .choosing {
                VStack(spacing: 12) {
                    Text(phase == .ready ? "ВАШ МАЛЕНЬКИЙ БОЛЬШОЙ ЖЕСТ" : "НЕМНОГО ЦВЕТОЧНОЙ МАГИИ")
                        .font(.system(size: 9, weight: .medium)).tracking(2.5)
                        .foregroundStyle(Color.ink.opacity(0.65))
                    Text(bouquet.name)
                        .font(.system(size: bouquet.name.count > 20 ? 29 : 34, weight: .semibold)).tracking(-1.2)
                        .multilineTextAlignment(.center)
                    Text(bouquet.mood).font(.system(size: 13)).foregroundStyle(Color.ink.opacity(0.7))
                }.padding(.horizontal, 28).position(x: width / 2, y: height * 0.226)
                    .transition(.opacity.combined(with: .offset(y: 12)))

                Ellipse().fill(Color.brandPurple.opacity(0.075))
                    .frame(width: width * 0.51, height: 25).blur(radius: 17)
                    .scaleEffect(reveal ? 1 : 0.2)
                    .position(x: width * 0.54, y: height * 0.739)

                Image(bouquet.image).resizable().scaledToFit()
                    .frame(width: width * 0.85, height: height * 0.445)
                    .shadow(color: Color(hex: 0x352344).opacity(0.09), radius: 14, x: 16, y: 21)
                    .scaleEffect(reveal ? 1 : 0.57, anchor: .bottom)
                    .rotationEffect(.degrees(reveal ? -3 : 8))
                    .offset(y: reveal ? 0 : 100)
                    .opacity(reveal ? 1 : 0)
                    .position(x: width * 0.5, y: height * 0.524)
                    .accessibilityLabel(bouquet.name)

                if phase == .assembling && !reduceMotion {
                    FlowerFlight(bouquet: bouquet, flying: flowersFlying)
                        .position(x: width * 0.5, y: height * 0.48)
                }
                if phase == .ready {
                    Button {
                        if favorites.contains(bouquet.id) { favorites.remove(bouquet.id) } else { favorites.insert(bouquet.id) }
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    } label: {
                        Image(systemName: favorites.contains(bouquet.id) ? "heart.fill" : "heart")
                            .font(.system(size: 20)).foregroundStyle(favorites.contains(bouquet.id) ? Color.brandPurple : Color.ink)
                            .frame(width: 46, height: 46)
                            .modifier(BrandGlass(shape: Circle()))
                    }.position(x: width - 46, y: height * 0.70)
                        .accessibilityLabel(favorites.contains(bouquet.id) ? "Убрать из избранного" : "В избранное")
                }
            }
        }
    }

    private func chooser(width: CGFloat, bottom: CGFloat) -> some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.ink.opacity(0.12)).frame(width: 31, height: 3).padding(.top, 12)
            Text("Что скажут ваши цветы?")
                .font(.system(size: 20, weight: .semibold)).tracking(-0.6)
                .padding(.top, 16)
            carousel(width: width).frame(height: 164).padding(.top, 10)
            VStack(spacing: 6) {
                Text(bouquet.name).font(.system(size: 16, weight: .medium)).lineLimit(1).minimumScaleFactor(0.8)
                    .id("name-\(bouquet.id)").transition(.opacity)
                Text(bouquet.priceLabel).font(.system(size: 13)).foregroundStyle(Color.ink.opacity(0.62))
                    .contentTransition(.numericText())
            }.frame(height: 47).padding(.horizontal, 24)
            HStack(spacing: 5) {
                ForEach(Bouquet.collection.indices, id: \.self) { i in
                    Capsule().fill(positiveModulo(position, 5) == i ? Color.brandPurple : Color.brandPurple.opacity(0.15))
                        .frame(width: positiveModulo(position, 5) == i ? 16 : 4, height: 4)
                }
            }.padding(.top, 11).padding(.bottom, 17)
            Button(action: assemble) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkle").font(.system(size: 17))
                    Text("Собрать мой букет").font(.system(size: 15, weight: .medium))
                    Spacer()
                    Image(systemName: "arrow.right").font(.system(size: 16))
                }.padding(.horizontal, 23).frame(height: 53)
                    .foregroundStyle(.white).background(Color.brandPurple, in: Capsule())
            }.padding(.horizontal, 28).accessibilityIdentifier("assembleBouquet")
            Text("СОБРАНО С ЛЮБОВЬЮ В GETBUKET")
                .font(.system(size: 7.5, weight: .medium)).tracking(1.8)
                .foregroundStyle(Color.ink.opacity(0.35)).padding(.top, 13)
                .padding(.bottom, max(bottom, 17))
        }
        .frame(width: width)
        .background(Color.white, in: UnevenRoundedRectangle(topLeadingRadius: 33, topTrailingRadius: 33))
        .shadow(color: Color.black.opacity(0.04), radius: 24, x: 0, y: -10)
    }

    private func carousel(width: CGFloat) -> some View {
        ZStack {
            ForEach(0..<(Bouquet.collection.count * 3), id: \.self) { index in
                let item = Bouquet.collection[index % Bouquet.collection.count]
                let distance = CGFloat(index - position) + drag / spacing
                let closeness = min(abs(distance), 1)
                Image(item.image).resizable().scaledToFit()
                    .frame(width: 137, height: 157)
                    .shadow(color: Color.black.opacity(0.09 * (1 - closeness)), radius: 5, x: 2, y: 7)
                    .scaleEffect(1 - closeness * 0.28)
                    .rotationEffect(.degrees(Double(distance.clamped(to: -2...2)) * 9))
                    .opacity(abs(distance) > 2.2 ? 0 : 1 - closeness * 0.7)
                    .blur(radius: closeness * 0.7)
                    .offset(x: distance * spacing, y: closeness * 10)
                    .zIndex(10 - Double(abs(distance)))
                    .onTapGesture { select(index) }
                    .accessibilityHidden(index != position)
            }
        }
        .frame(width: width, height: 164).contentShape(Rectangle()).clipped()
        .gesture(DragGesture(minimumDistance: 7)
            .onChanged { drag = $0.translation.width }
            .onEnded { value in
                let predicted = value.predictedEndTranslation.width
                let shift = (predicted / spacing).rounded().clamped(to: -2...2)
                withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                    position = min(max(position - Int(shift), 1), 13)
                    drag = 0
                }
                UISelectionFeedbackGenerator().selectionChanged()
                normalizePosition()
            })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Выбор букета")
        .accessibilityValue("\(bouquet.name), \(bouquet.priceLabel)")
        .accessibilityAdjustableAction { direction in select(position + (direction == .increment ? 1 : -1)) }
    }

    private var assemblingCaption: some View {
        VStack(spacing: 15) {
            HStack(spacing: 6) {
                ForEach(0..<3) { i in
                    Capsule().fill(Color.brandPurple.opacity(step >= i ? 0.9 : 0.15)).frame(width: 22, height: 3)
                }
            }
            Text(steps[min(step, 2)]).font(.system(size: 13, weight: .medium))
                .id(step).transition(.opacity)
                .padding(.horizontal, 22).padding(.vertical, 12)
                .modifier(BrandGlass(shape: Capsule(), interactive: false))
        }
    }

    private func readyControls(bottom: CGFloat) -> some View {
        VStack(spacing: 17) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal").font(.system(size: 12))
                Text("Тот самый букет. Для того самого человека.").font(.system(size: 11))
            }.foregroundStyle(Color.ink.opacity(0.75))
            Button {
                bag.append(bouquet)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                showBag = true
            } label: {
                HStack {
                    Text("Выбрать букет").font(.system(size: 15, weight: .medium))
                    Spacer()
                    Text(bouquet.priceLabel).font(.system(size: 15, weight: .medium))
                    Image(systemName: "arrow.right").font(.system(size: 14)).padding(.leading, 4)
                }.padding(.horizontal, 22).frame(height: 55)
                    .foregroundStyle(.white).background(Color.brandPurple, in: Capsule())
            }.accessibilityIdentifier("selectBouquet")
            HStack(spacing: 12) {
                Button(action: reset) {
                    Label("Другой букет", systemImage: "arrow.left")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 18).frame(height: 40)
                        .modifier(BrandGlass(shape: Capsule()))
                }
                Button(action: assemble) {
                    Label("Ещё раз", systemImage: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 18).frame(height: 40)
                        .modifier(BrandGlass(shape: Capsule()))
                }
            }.foregroundStyle(Color.ink.opacity(0.75))
        }
        .padding(.horizontal, 27).padding(.bottom, max(bottom, 24) + 8)
    }

    private var bagSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(bag.isEmpty ? "Здесь скоро\nбудет красиво." : "Хороший выбор.")
                        .font(.system(size: 34, weight: .semibold)).tracking(-1)
                    Text(bag.isEmpty ? "Найдите букет, который скажет всё за вас." : "Цветы, которые вы выбрали для особенного человека.")
                        .font(.system(size: 15)).foregroundStyle(.secondary)
                    ForEach(Array(bag.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: 18) {
                            Image(item.image).resizable().scaledToFit().frame(width: 80, height: 110)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.name).font(.system(size: 16, weight: .medium))
                                Text(item.priceLabel).font(.system(size: 15)).foregroundStyle(Color.brandPurple)
                            }
                            Spacer()
                            Button { bag.remove(at: index) } label: { Image(systemName: "minus.circle").foregroundStyle(Color.ink.opacity(0.5)) }
                                .accessibilityLabel("Удалить \(item.name)")
                        }.padding(15).background(.white, in: RoundedRectangle(cornerRadius: 22))
                    }
                    if !bag.isEmpty {
                        HStack {
                            Text("Итого").font(.system(size: 18))
                            Spacer()
                            Text(bag.reduce(0) { $0 + $1.price }.formatted(.number.locale(Locale(identifier: "ru_RU"))) + " ₽")
                                .font(.system(size: 23, weight: .medium))
                        }.padding(.vertical, 4)
                        Label("Фото букета перед доставкой", systemImage: "camera")
                            .font(.system(size: 13)).foregroundStyle(.secondary)
                    }
                    Button { showBag = false; reset() } label: {
                        Text("Продолжить выбор").font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .foregroundStyle(.white).background(Color.brandPurple, in: Capsule())
                    }
                    Text("Демонстрация приложения. Заказ не отправляется.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }.padding(25)
            }
            .background(Color.brandSurface)
            .navigationTitle("Ваш выбор").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Готово") { showBag = false }.tint(.brandPurple) } }
        }.presentationDragIndicator(.visible).presentationCornerRadius(30)
    }

    private func select(_ index: Int) {
        withAnimation(.spring(response: 0.57, dampingFraction: 0.78)) { position = index.clamped(to: 1...13); drag = 0 }
        UISelectionFeedbackGenerator().selectionChanged()
        normalizePosition()
    }

    private func normalizePosition() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.65))
            guard phase == .choosing, drag == 0 else { return }
            if position < 4 || position > 10 {
                var transaction = Transaction(); transaction.disablesAnimations = true
                withTransaction(transaction) { position = positiveModulo(position, 5) + 5 }
            }
        }
    }

    private func assemble() {
        assemblyTask?.cancel()
        reveal = false; flowersFlying = false; step = 0
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.spring(response: reduceMotion ? 0.2 : 0.85, dampingFraction: 0.9)) { phase = .assembling }
        assemblyTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(0.15))
                flowersFlying = true
                try await Task.sleep(for: .seconds(reduceMotion ? 0.1 : 0.55))
                withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 1.8, dampingFraction: 0.73)) { reveal = true }
                try await Task.sleep(for: .seconds(reduceMotion ? 0.1 : 0.9))
                withAnimation { step = 1 }
                try await Task.sleep(for: .seconds(reduceMotion ? 0.1 : 1.1))
                withAnimation { step = 2 }
                try await Task.sleep(for: .seconds(reduceMotion ? 0.1 : 1.2))
                withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) { phase = .ready }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch { return }
        }
    }

    private func reset() {
        assemblyTask?.cancel()
        withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) { phase = .choosing; reveal = false; flowersFlying = false; drag = 0 }
    }

    private func runDemo() {
        demoTask?.cancel()
        reset(); position = 5; demoRunning = true
        demoTask = Task { @MainActor in
            do {
                for next in [6, 7, 8, 9, 5] {
                    try await Task.sleep(for: .seconds(1.4))
                    select(next)
                }
                try await Task.sleep(for: .seconds(1.2))
                assemble()
                try await Task.sleep(for: .seconds(7))
                demoRunning = false
            } catch { demoRunning = false }
        }
    }

    private func positiveModulo(_ value: Int, _ divisor: Int) -> Int { (value % divisor + divisor) % divisor }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self { min(max(self, range.lowerBound), range.upperBound) }
}
