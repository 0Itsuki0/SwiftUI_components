//
//  MultiSelectBox.swift
//  SwiftUIDemo5
//
//  Created by Itsuki on 2025/02/02.
//


import SwiftUI


struct MultiSelectBoxDemoView: View {
    @State private var options = Array(1...10).map({SelectOption(text:"Option \($0)")})
    @State private var selectedOptions: [SelectOption] = []
    @State private var showMultiSelectDropdown: Bool = false
    
    var body: some View {
        VStack {
            MultiSelectBox(
                options: options,
                onCreate: {new in },
                onScrollBottom: {
                    let newOptions = Array(options.count+1...options.count+5).map({SelectOption(text:"Option \($0)")})
                    options.append(contentsOf: newOptions)
                },
                selectedOptions: $selectedOptions,
                showDropdown: $showMultiSelectDropdown,
                maxItemDisplayed: 5
            )
            
            Text("Some other stuff!")
        }
        .padding(.top, 48)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.gray.opacity(0.2))
        .onTapGesture {
            showMultiSelectDropdown = false
        }
    }
}

private struct SelectOption: Identifiable, Hashable {
    let text: String
    var id: String { text }
}

private struct MultiSelectBox: View {
    var options: [SelectOption]
    var onCreate: ((SelectOption) -> Void)? = nil
    var onScrollBottom: (() async -> Void)? = nil
    
    @Binding var selectedOptions: [SelectOption]
    @Binding var showDropdown: Bool

    var maxItemDisplayed: Int = 3
    var optionHeight: CGFloat = 48

    @State private var scrollPosition: SelectOption.ID?
    @State private var input: String = ""
    @State private var lastInputBeforeDelete: String = ""
    @FocusState private var inputFocused: Bool
    
    @State private var optionContainerSize: CGSize = .zero
    @State private var selectedOptionsArranged: [[SelectOption]] = []

    @State private var highlightedOption: SelectOption? = nil
    
    // styling/formatting constants
    static private let newOptionEmptyStringCount = 2
    static private let emptyStringSpacing: CGFloat = 4.0
    
    private let optionCollectionViewTrailingPadding: CGFloat = 8
    private let lineSpacing: CGFloat = 12
    
    private let textFieldHorizontalPadding: CGFloat = 8
    private let textFieldVerticalPadding: CGFloat = 4
    private let inputSpacingString = Array.init(repeating: " ", count: Self.newOptionEmptyStringCount + 2).joined()
    private let newOptionSpacingString = Array.init(repeating: " ", count: Self.newOptionEmptyStringCount).joined()
    
    static private let inputFontSize: CGFloat = 16
    private let font = UIFont.systemFont(ofSize: Self.inputFontSize)
    
    private struct InputFocusState: Equatable, Hashable {
        let inputFocused: Bool
        let showDropdown: Bool
    }
    private var inputFocusState: InputFocusState {
        return InputFocusState(inputFocused: inputFocused, showDropdown: showDropdown)
    }
    
    

    var body: some View {
        let lastInput = getLastInput(input)
        let unselected = options.filter({!selectedOptions.contains($0)})
        let filteredOptions = lastInput.isEmpty ? unselected : unselected.filter({$0.text.lowercased().contains(lastInput.lowercased())})
        let exactMatch = options.contains(where: {$0.text == lastInput}) || selectedOptions.contains(where: {$0.text == lastInput})

        Button(action: {
            showDropdown.toggle()
        }, label: {
            
            HStack {
                
                // to keep the size of the option container
                TextField("", text: $input, axis: .vertical)
                    .textFieldStyle(CustomTextFieldStyle(horizontalPadding: textFieldHorizontalPadding, verticalPadding: textFieldVerticalPadding, backgroundColor: .white))
                    .autocorrectionDisabled()
                    .foregroundStyle(.clear)
                    .focusable(false)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(lineSpacing)
                    .overlay(content: {
                        GeometryReader { proxy in
                            DispatchQueue.main.async {
                                self.optionContainerSize = proxy.size
                            }
                            return Color.clear
                        }
                    })
                    .allowsHitTesting(false)
                    .overlay(alignment: .topLeading, content: {
                        
                        // tabs (background)
                        let itemVerticalPadding =  textFieldVerticalPadding/2
                        CollectionView(
                            options: selectedOptions,
                            containerSize: optionContainerSize,
                            optionsArranged:  $selectedOptionsArranged,
                            highlightedOption: $highlightedOption,
                            horizontalSpacing: Self.emptyStringSpacing * CGFloat(Self.newOptionEmptyStringCount),
                            verticalSpacing: lineSpacing - itemVerticalPadding * 2,
                            itemHorizontalPadding: Self.emptyStringSpacing,
                            itemVerticalPadding: itemVerticalPadding,
                            containerHorizontalPadding: textFieldHorizontalPadding,
                            containerVerticalPadding: textFieldVerticalPadding/2,
                            font: font,
                            viewTrailingPadding: optionCollectionViewTrailingPadding
                        )
                    })
                    .overlay(alignment: .leading, content: {
                        // to show the text above the tabs
                        TextView(text: $input,
                                 hideCursor: highlightedOption != nil,
                                 horizontalPadding: textFieldHorizontalPadding, verticalPadding: textFieldVerticalPadding, lineSpacing: lineSpacing, font: font)
                            .foregroundStyle(.black)
                            .focused($inputFocused)
                            .allowsHitTesting(false)
                    })

                
                Image(systemName: "chevron.down")
                    .fontWeight(.semibold)
                    .rotationEffect(.degrees((showDropdown ? -180 : 0)))
                    .animation(nil, value: showDropdown)
            }

        })
        .font(.system(size: Self.inputFontSize))

        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, showDropdown ? 16 : 4)
        .overlay(alignment: .top, content: {
            // selection menu
            if (showDropdown) {
                let optionCount = getOptionCount(exactMatch: exactMatch, filteredOptionsCount: filteredOptions.count)
                let scrollViewHeight: CGFloat = optionCount > maxItemDisplayed ? (optionHeight*CGFloat(maxItemDisplayed)) : (optionHeight*CGFloat(optionCount))
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        
                        if filteredOptions.isEmpty && onCreate == nil {
                            
                            HStack {
                                Text("No option found.")
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .padding(.horizontal, 16)
                            .frame(height: optionHeight)
                        }
                        
                        if filteredOptions.isEmpty && onCreate != nil && exactMatch {
                            
                            HStack {
                                Text("Option already added.")
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .padding(.horizontal, 16)
                            .frame(height: optionHeight)
                        }
                        
                        // creatable, input is not empty & is no exact match
                        if onCreate != nil, !exactMatch, !lastInput.isEmpty {
                            Button(action: {
                                createNewOption()
                            }, label: {
                                HStack {
                                    Text("Create new option: \(lastInput)")
                                    Spacer()
                                }
                            })
                            .contentShape(Rectangle())
                            .padding(.horizontal, 16)
                            .frame(height: optionHeight)
                        }
                        
                        ForEach(filteredOptions) { option in
                            Button(action: {
                                selectedOptions.append(option)
                                showDropdown = false

                            }, label: {
                                Text(option.text)
                                Spacer()
                            })
                            .contentShape(Rectangle())
                            .padding(.horizontal, 16)
                            .frame(height: optionHeight)
                            .onAppear {
                                guard let index = filteredOptions.firstIndex(where: {$0.id == option.id}) else { return }
                                if index == filteredOptions.count - 1 {
                                    Task {
                                        await onScrollBottom?()
                                    }
                                }
                            }
                        }
                        
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $scrollPosition)
                .scrollDisabled(options.count <= maxItemDisplayed)
                .frame(height: scrollViewHeight)
                .foregroundStyle(Color.white)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.black))
                .padding(.top, optionContainerSize.height+8)
                .onAppear {
                    scrollPosition = options.first?.id
                }
            }

        })
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    highlightedOption = nil
                }
            , isEnabled: highlightedOption != nil)
        .foregroundStyle(Color.white)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black))
        .zIndex(100)
        .onChange(of: inputFocusState, initial: true, { old, new in
            // showDropdown change
            if old.showDropdown != new.showDropdown {
                inputFocused = showDropdown
                if !showDropdown {
                    highlightedOption = nil
                    formatInput()
                }
                return
            }
            
            // input focusedState change
            // return button pressed
            if !inputFocused, showDropdown {
                createNewOption()
            }

        })
        .onChange(of: highlightedOption, {
            if highlightedOption != nil {
                showDropdown = true
            }
        })
        .onChange(of: input, { old, new in
            // programatic change
            if abs(old.count - new.count) > 1 {
                return
            }
            checkInput(old: old, new: new)
        })
        .onChange(of: selectedOptionsArranged, { old, new in
            formatInput(lastInputBeforeDelete)
            lastInputBeforeDelete = ""
        })
  
        // for test
        .onAppear{
            selectedOptions.append(contentsOf: options[0..<5])
            selectedOptions.append(contentsOf: [SelectOption(text: "dd"), SelectOption(text: "SelectOptionSelectOptionSelectOptionSelectOptionSelectOption")])
            showDropdown = true
        }

    }
    
    func checkInput(old: String, new: String) {
        // inserting: don't do anything
        if new.count > old.count {
            highlightedOption = nil
            return
        }
        
        // delete highlighted option, keep the current input if any
        if highlightedOption != nil {
            let oldInput = getLastInput(old)
            lastInputBeforeDelete = oldInput
            self.selectedOptions.removeAll(where: {$0 == highlightedOption!})
            highlightedOption = nil
            return
        }
        
        // user press on delete & cursor is right after the last selected option
        guard let lastLine = new.split(separator: "\r\n").last else { return }
        // more than two space until the target, return
        if lastLine.hasSuffix("  ") { return }
        let trimmed = lastLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let lastOption = selectedOptions.last else {return}
        
        if let re = try? Regex(lastOption.text), let range = trimmed.firstRange(of: re) {
            if range.upperBound.utf16Offset(in: trimmed) == trimmed.count {
                highlightedOption = selectedOptions.last
                return
            }
        }
        
        // maybe overflow case (instead of match the overflowed version at first afterward to avoid calculation)
        guard let lastRow = selectedOptionsArranged.last else { return }
        if lastRow.count == 1 && overflow(lastRow.first!.text) {

            guard let reOverflow = try? Regex(buildOverflowString(lastOption.text)) else { return }
            if let range = trimmed.firstRange(of: reOverflow) {

                if range.upperBound.utf16Offset(in: trimmed) == trimmed.count {
                    highlightedOption = selectedOptions.last
                    return
                }
            }
        }
    }
    
    func getOptionCount(exactMatch: Bool, filteredOptionsCount: Int) -> Int {
        if onCreate == nil  {
            return exactMatch ? 1 : filteredOptionsCount
        }
        
        if exactMatch {
            return filteredOptionsCount == 0 ? 1 : filteredOptionsCount
        }
            
        // not exact match + able to create new
        return filteredOptionsCount + 1
    }


    func createNewOption() {
        defer { showDropdown = false }
        guard let onCreate else {return}
        let lastInput = getLastInput(input)
        guard !lastInput.isEmpty else {return}
        let exactMatch = options.contains(where: {$0.text == lastInput}) || selectedOptions.contains(where: {$0.text == lastInput})
        if exactMatch { return }
        let new = SelectOption(text: lastInput)
        selectedOptions.append(new)
        onCreate(new)
    }
    
    func formatInput(_ currentInput: String = "") {
        var inputArray: [String] = []
        for row in selectedOptionsArranged {
            // overflow
            if row.count == 1, overflow(row.first!.text) {
                let input = buildOverflowString(row.first!.text)
                inputArray.append(input)
                continue
            }
            
            let input = row.map({$0.text}).joined(separator: inputSpacingString)
            inputArray.append(input)

        }
        input = "\(inputArray.joined(separator: "\r\n"))\(newOptionSpacingString)\(currentInput)"
    }
    
    func getFilteredOptions() -> [SelectOption] {
        let lastInput = getLastInput(input)
        let unselected = options.filter({!selectedOptions.contains($0)})
        let filteredOptions = lastInput.isEmpty ? unselected : unselected.filter({$0.text.lowercased().contains(lastInput.lowercased())})
        return filteredOptions
    }
    
    func getLastInput(_ input: String) -> String {
        
        guard let lastLine = input.split(separator: "\r\n").last else {return ""}
        var trimmed = lastLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let lastRow = selectedOptionsArranged.last else {return "" }
        
        if lastRow.count == 1 && overflow(lastRow.first!.text) {
            trimmed.replace(buildOverflowString(lastRow.first!.text), with: "", maxReplacements: 1)
            let lastInput = trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
            return lastInput
        }
        // each appearance should only be removed exactly once on first appear
        for option in lastRow {
            trimmed.replace(option.text, with: "", maxReplacements: 1)
        }
        
        let lastInput = trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        return lastInput
    }
    
    func buildOverflowString(_ string: String) -> String {
        let ellipse = "..."
        let textThatFit = string.stringThatFits(font: font, width: optionContainerSize.width - textFieldHorizontalPadding * 2 - optionCollectionViewTrailingPadding - Self.emptyStringSpacing - ellipse.width(font: font))
        return "\(textThatFit)\(ellipse)"
    }
    
    func overflow(_ string: String) -> Bool {
        return string.overflow(font: font, width: optionContainerSize.width - textFieldHorizontalPadding * 2 - optionCollectionViewTrailingPadding)
    }

}


private struct CollectionView: View {
    var options: [SelectOption]
    var containerSize: CGSize
    @Binding var optionsArranged: [[SelectOption]]
    @Binding var highlightedOption: SelectOption?

    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8
    var itemHorizontalPadding: CGFloat = 4
    var itemVerticalPadding: CGFloat = 2
    var containerHorizontalPadding: CGFloat = 8
    var containerVerticalPadding: CGFloat = 2
    var font: UIFont = .systemFont(ofSize: 16)
    var viewTrailingPadding: CGFloat = 8

    var body: some View {
        let cursorHeight = font.lineHeight + itemVerticalPadding * 2 + 4
        VStack(alignment: .leading, spacing: verticalSpacing) {
            ForEach(0..<optionsArranged.count, id: \.self) { row in
                let itemsInRow = optionsArranged[row]
                HStack(spacing: horizontalSpacing) {
                    ForEach(0..<itemsInRow.count, id: \.self) { column in
                        let option = itemsInRow[column]
                        Text(option.text)
                            .lineLimit(1)
                            .font(Font(font))
                            .padding(.vertical, itemVerticalPadding)
                            .padding(.horizontal, itemHorizontalPadding)
                            .foregroundStyle(.clear)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color(uiColor: .lightGray).opacity(highlightedOption == option ? 0.6 : 0.2)))
                            .selectionCursor(height: cursorHeight, color: .blue, isHidden: highlightedOption != option)
                            .highPriorityGesture(
                                TapGesture()
                                    .onEnded { _ in
                                        highlightedOption = option
                                    }
                            )
                    }

                }
                
            }

        }
        .padding(.horizontal, containerHorizontalPadding-itemHorizontalPadding)
        .padding(.vertical, containerVerticalPadding)
        .padding(.trailing, viewTrailingPadding) // so that cursor does not overlap in the case of option overflow
        .onChange(of: options, initial: true, {
            optionsArranged = calculateArrangedOptions()
        })
        .onChange(of: containerSize, initial: true, {
            optionsArranged = calculateArrangedOptions()
        })

    }
    
    
    func calculateArrangedOptions() -> [[SelectOption]] {
        let containerWidth = containerSize.width - containerHorizontalPadding * 2 - viewTrailingPadding
        var arrangedItems: [[SelectOption]] = []
        var currentRowWidth: CGFloat = 0
        
        for i in 0..<options.count {
            let item = options[i]
            
            let itemWidth = item.text.width(font: font) + itemHorizontalPadding * 2
            // first item
            if i == 0 {
                arrangedItems.append([item])
                currentRowWidth = itemWidth
                continue
            }
            
            if currentRowWidth + horizontalSpacing + itemWidth > containerWidth {
                // start new row
                arrangedItems.append([item])
                currentRowWidth = itemWidth
            } else {
                // add to current row
                arrangedItems[arrangedItems.count - 1].append(item)
                currentRowWidth = currentRowWidth + horizontalSpacing + itemWidth
            }
        }
        return arrangedItems
    }
}

private extension String {
    
    func width(font: UIFont) -> CGFloat {
        let constraintRectangle = CGSize(width: .greatestFiniteMagnitude, height: font.lineHeight)
        let boundingBox = self.boundingRect(with: constraintRectangle, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.width)
    }
    
    func overflow(font: UIFont, width: CGFloat) -> Bool {
        return self.width(font: font) > width
    }
    
    func countThatFits(font: UIFont, width: CGFloat, line: Int = 1) -> Int {
        if width <= 0 {
            return 0
        }
        let fontRef = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        let attributes = [kCTFontAttributeName : fontRef]
        let attributedString = NSAttributedString(string: self, attributes: attributes as [NSAttributedString.Key : Any])
        let frameSetterRef = CTFramesetterCreateWithAttributedString(attributedString as CFAttributedString)

        var characterFitRange: CFRange = CFRange()
        
        CTFramesetterSuggestFrameSizeWithConstraints(frameSetterRef, CFRangeMake(0, 0), nil, CGSize(width: width, height: font.lineHeight * CGFloat(line)), &characterFitRange)
        
        var charCount = Int(characterFitRange.length)
        var index: String.Index = .init(utf16Offset: charCount, in: self)
        // needed due to counts returned from CTFramesetterSuggestFrameSizeWithConstraints is a little off
        while String(self[startIndex..<index]).width(font: font) > width && charCount > 0 {
            charCount -= 1
            index = .init(utf16Offset: charCount, in: self)
        }
        
        return charCount
    }

    
    func stringThatFits(font: UIFont, width: CGFloat, line: Int = 1) -> String {
        if width <= 0 {
            return ""
        }
        let charCount: Int = countThatFits(font: font, width: width, line: line)
        let index: String.Index = .init(utf16Offset: charCount, in: self)

        return String(self[startIndex..<index])
    }

}


extension View {
    func selectionCursor(height: CGFloat, color: Color, isHidden: Bool) -> some View {
        if isHidden {return AnyView(self)}
        let cursor = RoundedRectangle(cornerRadius: 4)
            .union(
                Circle()
                    .size(width: 10, height: 10)
                    .offset(x: -4)
            )
            .fill(color)
            .frame(width: 2, height: height)

        return AnyView(
            self
                .overlay(content: {
                    Rectangle()
                        .fill(color.opacity(0.2))
                })
                .overlay(alignment: .bottomLeading, content: {
                    cursor
                })
                .overlay(alignment: .topTrailing, content: {
                    cursor
                        .rotationEffect(.degrees(180))
                })
        )

    }
}


private struct CustomTextFieldStyle: TextFieldStyle {
    var horizontalPadding: CGFloat = 8
    var verticalPadding: CGFloat = 4
    var backgroundColor: Color

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .background(RoundedRectangle(cornerRadius: 8).fill(backgroundColor))
    }
}


private class _UITextView: UITextView {
    
    // disable all action
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
       return false
    }
    
    // disable autofill action
    override func buildMenu(with builder: any UIMenuBuilder) {
        builder.remove(menu: .autoFill)
        super.buildMenu(with: builder)
    }
}


private struct TextView: UIViewRepresentable {
    
    @Binding var text: String
    var hideCursor: Bool = false
    
    var horizontalPadding: CGFloat = 8
    var verticalPadding: CGFloat = 4
    var lineSpacing: CGFloat = 12
    var font: UIFont = UIFont.systemFont(ofSize: 16)

    func makeUIView(context: Context) -> _UITextView {
        let textField = _UITextView(frame: .zero)
        textField.delegate = context.coordinator

        textField.autocorrectionType = .no // hide auto correction
        textField.textContentType = .none
        
        textField.backgroundColor = .clear
        textField.textContainer.lineFragmentPadding = .zero
        textField.textContainerInset = .init(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
        
        return textField
    }
    
    func updateUIView(_ uiView: _UITextView, context: Context) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        let attributes = [
            NSAttributedString.Key.paragraphStyle : style,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
        uiView.attributedText = NSAttributedString(string: text, attributes: attributes)

        // make sure cursor is always at end
        uiView.selectedTextRange = uiView.textRange(from: uiView.endOfDocument, to: uiView.endOfDocument)
        uiView.tintColor = uiView.tintColor.withAlphaComponent(hideCursor ? 0 : 1)
    }
    
}



private extension TextView {
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextView

        init(_ control: TextView) {
            self.parent = control
            super.init()
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            // to disable the up, down, left, right keyboard buttons
            textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)

            guard let text = textView.text else { return }
            DispatchQueue.main.async {
                self.parent.text = text
            }
        }
        
        
        // different from textField, textview return key insert new line by default
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text.first?.isNewline == true {
                textView.resignFirstResponder()
                return false
            }
            return true
        }
    }
}





#Preview {
    MultiSelectBoxDemoView()

    
//    return Text("some option")
//        .padding(.horizontal, 4)
//        .foregroundStyle(.white)
//        .background(Rectangle().fill(.red))
//        .selectionCursor(height: 30, color: .blue, isHidden: false)

        
}
