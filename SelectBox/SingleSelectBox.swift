//
//  SingleSelectBox.swift
//  SwiftUIDemo5
//
//  Created by Itsuki on 2025/02/02.
//


import SwiftUI



struct SingleSelectBoxDemoView: View {
    @State private var options = Array(1...5).map({SelectOption(text:"Option \($0)")})
    @State private var selectedOption: SelectOption? = nil
    @State private var showSingleSelectDropdown: Bool = true

    var body: some View {
        VStack {
            SingleSelectBox(
                options: options,
                onCreate: {new in },
                onScrollBottom: {
                    let newOptions = Array(options.count+1...options.count+5).map({SelectOption(text:"Option \($0)")})
                    options.append(contentsOf: newOptions)
                },
                selectedOption: $selectedOption,
                showDropdown: $showSingleSelectDropdown)
            .frame(width: 320)
        }
        .padding(.top, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.gray.opacity(0.2))
        .onTapGesture {
            showSingleSelectDropdown = false
        }
    }
}


private struct SelectOption: Identifiable, Hashable {
    let text: String
    var id: String { text }
}

private struct SingleSelectBox: View {
    let options: [SelectOption]
    var onCreate: ((SelectOption) -> Void)? = nil
    var onScrollBottom: (() async -> Void)? = nil
    
    @Binding var selectedOption: SelectOption?
    @Binding var showDropdown: Bool

    var buttonHeight: CGFloat = 50
    var maxItemDisplayed: Int = 3

              
    @State private var scrollPosition: SelectOption.ID?
    @State private var input: String = ""
    @FocusState private var inputFocused: Bool


    var body: some View {
        let filteredOptions = input.isEmpty ? options : options.filter({$0.text.lowercased().contains(input.lowercased())})
        let exactMatch = options.contains(where: {$0.text == input})
        
        VStack {

            VStack(spacing: 0) {
                // selected item
                Button(action: {
                    showDropdown.toggle()
                }, label: {
                    HStack {
                        TextField(text: $input, label: {})
                            .textFieldStyle(ClearableTextField(clearable: !input.isEmpty, focused: $inputFocused))
                            .foregroundStyle(.black)
                            .focused($inputFocused)
                            .multilineTextAlignment(.leading)
                            .overlay(alignment: .leading, content: {
                                if input.isEmpty {
                                    Text(selectedOption?.text ?? "")
                                        .foregroundStyle(.black)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                }
                            })

                        Image(systemName: "chevron.down")
                            .fontWeight(.semibold)
                            .rotationEffect(.degrees((showDropdown ? -180 : 0)))
                            .animation(nil, value: showDropdown)
                    }

                })
                .padding(.horizontal, 12)
                .frame(height: buttonHeight, alignment: .leading)

                // selection menu
                if (showDropdown) {
                    let optionCount = (onCreate == nil || exactMatch || input.isEmpty) ? filteredOptions.count : filteredOptions.count + 1
                    let scrollViewHeight: CGFloat = optionCount > maxItemDisplayed ? (buttonHeight*CGFloat(maxItemDisplayed)) : (buttonHeight*CGFloat(optionCount))
                    
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            
                            if filteredOptions.isEmpty && onCreate == nil {
                                HStack {
                                    Text("No option found.")
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .frame(height: buttonHeight, alignment: .leading)
                            }
                            
                            // creatable, input is not empty & is no exact match
                            if onCreate != nil, !exactMatch, !input.isEmpty {
                                Button(action: {
                                    createNewOption()
                                }, label: {
                                    HStack {
                                        Text("Create new option: \(input)")
                                        Spacer()
                                    }
                                
                                })
                                .padding(.horizontal, 16)
                                .frame(height: buttonHeight, alignment: .leading)
                            }
                            
                            ForEach(filteredOptions) { option in
                                Button(action: {
                                    selectedOption = option
                                    showDropdown = false

                                }, label: {
                                    HStack {
                                        Text(option.text)
                                        Spacer()
                                        if (option == selectedOption) {
                                            Image(systemName: "checkmark.circle.fill")
                                        }
                                    }
                                
                                })
                                .padding(.horizontal, 16)
                                .frame(height: buttonHeight, alignment: .leading)
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
                    .onAppear {
                        scrollPosition = selectedOption?.id
                    }
                }
                
            }
            .foregroundStyle(Color.white)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.black))
            
        }
        .frame(height: buttonHeight, alignment: .top)
        .zIndex(100)
        .onChange(of: showDropdown, initial: true, {
            input = ""
            inputFocused = showDropdown
        })
        .onChange(of: inputFocused, {
            if onCreate != nil, !inputFocused, showDropdown {
                createNewOption()
            }
        })
    }
    
    func createNewOption() {
        guard let onCreate else {return}
        let exactMatch = options.contains(where: {$0.text == input})
        if exactMatch { return }

        let new = SelectOption(text: input)
        selectedOption = new
        onCreate(new)
        showDropdown = false
    }
}

private struct ClearableTextField: TextFieldStyle {
    var clearable: Bool
    var focused: FocusState<Bool>.Binding
    var horizontalPadding: CGFloat = 8
    var verticalPadding: CGFloat = 4

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.vertical, verticalPadding)
            .padding(.leading, horizontalPadding)
            .padding(.trailing, clearable ? horizontalPadding + 24 : horizontalPadding)
            .overlay(alignment: .trailing, content: {
                if clearable && focused.wrappedValue {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray.opacity(0.8))
                        .padding(.trailing, horizontalPadding)
                }
            })
            .background(RoundedRectangle(cornerRadius: 8).fill(.white))
    }
}



#Preview {
    SingleSelectBoxDemoView()
}
