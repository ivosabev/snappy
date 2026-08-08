import AppKit

final class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    private var rows: [ZoneRowView] = []

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Snappy Preferences"
        window.isReleasedWhenClosed = false
        self.init(window: window)
        window.delegate = self
        window.contentView = buildContent()
        window.center()
    }

    private func buildContent() -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 520))

        let title = NSTextField(labelWithString: "Window sizes (% of screen)")
        title.font = .systemFont(ofSize: 13, weight: .semibold)
        title.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(title)

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        rows = SnapZone.allCases.map { zone in
            let row = ZoneRowView(zone: zone)
            row.onChange = { [weak self] zone, width, height in
                self?.update(zone: zone, width: width, height: height)
            }
            stack.addArrangedSubview(row)
            return row
        }
        reloadRows()

        let reset = NSButton(title: "Reset to defaults", target: self, action: #selector(resetDefaults))
        reset.bezelStyle = .rounded
        reset.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(reset)

        let hint = NSTextField(wrappingLabelWithString: "Drag any window to a screen corner or edge center. Release to snap it to that zone’s size.")
        hint.textColor = .secondaryLabelColor
        hint.font = .systemFont(ofSize: 11)
        hint.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hint)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            title.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),

            stack.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            reset.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 16),
            reset.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),

            hint.topAnchor.constraint(equalTo: reset.bottomAnchor, constant: 14),
            hint.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            hint.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            hint.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -20)
        ])

        return container
    }

    private func reloadRows() {
        let sizes = Preferences.shared.sizes
        for row in rows {
            let size = sizes.size(for: row.zone)
            row.setValues(widthPercent: size.widthFraction * 100, heightPercent: size.heightFraction * 100)
        }
    }

    private func update(zone: SnapZone, width: CGFloat, height: CGFloat) {
        var sizes = Preferences.shared.sizes
        sizes.set(
            ZoneSize(
                widthFraction: min(max(width / 100, 0.1), 1),
                heightFraction: min(max(height / 100, 0.1), 1)
            ),
            for: zone
        )
        Preferences.shared.sizes = sizes
    }

    @objc private func resetDefaults() {
        Preferences.shared.resetSizes()
        reloadRows()
    }

    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

final class ZoneRowView: NSView {
    let zone: SnapZone
    var onChange: ((SnapZone, CGFloat, CGFloat) -> Void)?

    private let widthField = NSTextField()
    private let heightField = NSTextField()

    init(zone: SnapZone) {
        self.zone = zone
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let name = NSTextField(labelWithString: zone.displayName)
        name.font = .systemFont(ofSize: 12)
        name.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        configure(widthField)
        configure(heightField)
        widthField.placeholderString = "W %"
        heightField.placeholderString = "H %"

        let wLabel = NSTextField(labelWithString: "W")
        wLabel.font = .systemFont(ofSize: 11)
        wLabel.textColor = .secondaryLabelColor
        let hLabel = NSTextField(labelWithString: "H")
        hLabel.font = .systemFont(ofSize: 11)
        hLabel.textColor = .secondaryLabelColor

        let stack = NSStackView(views: [name, NSView(), wLabel, widthField, hLabel, heightField])
        stack.orientation = .horizontal
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 28),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            widthField.widthAnchor.constraint(equalToConstant: 52),
            heightField.widthAnchor.constraint(equalToConstant: 52)
        ])

        widthField.delegate = self
        heightField.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setValues(widthPercent: CGFloat, heightPercent: CGFloat) {
        widthField.stringValue = String(Int(widthPercent.rounded()))
        heightField.stringValue = String(Int(heightPercent.rounded()))
    }

    private func configure(_ field: NSTextField) {
        field.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        field.alignment = .right
        field.isEditable = true
        field.isBordered = true
        field.bezelStyle = .roundedBezel
    }

    private func emitChange() {
        let width = CGFloat(Double(widthField.stringValue) ?? 50)
        let height = CGFloat(Double(heightField.stringValue) ?? 50)
        onChange?(zone, width, height)
    }
}

extension ZoneRowView: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        emitChange()
    }
}
