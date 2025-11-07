//
//  SignUpView.swift
//  Chukkoomi
//
//  Created by 서지민 on 11/7/25.
//

import SwiftUI
import ComposableArchitecture

struct SignUpView: View {

    let store: StoreOf<SignUpFeature>
    @Environment(\.dismiss) var dismiss

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(spacing: 24) {
                    // 타이틀
                    Text("회원가입")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 60)

                    // 이메일 입력 필드
                    VStack(alignment: .leading, spacing: 8) {
                        Text("이메일")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            TextField(
                                "이메일을 입력하세요",
                                text: viewStore.binding(
                                    get: \.email,
                                    send: SignUpFeature.Action.emailChanged
                                )
                            )
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)

                            // 중복 확인 버튼
                            Button {
                                viewStore.send(.checkEmailButtonTapped)
                            } label: {
                                Text("중복확인")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                            .disabled(viewStore.email.isEmpty || viewStore.isLoading)
                        }

                        // 이메일 검증 결과
                        if let isEmailValid = viewStore.isEmailValid {
                            Text(isEmailValid ? "✓ 사용 가능한 이메일입니다" : "✗ 사용할 수 없는 이메일입니다")
                                .font(.caption)
                                .foregroundColor(isEmailValid ? .green : .red)
                        }
                    }

                    // 비밀번호 입력 필드
                    VStack(alignment: .leading, spacing: 8) {
                        Text("비밀번호")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        SecureField(
                            "비밀번호 (8자 이상)",
                            text: viewStore.binding(
                                get: \.password,
                                send: SignUpFeature.Action.passwordChanged
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                    }

                    // 닉네임 입력 필드
                    VStack(alignment: .leading, spacing: 8) {
                        Text("닉네임")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextField(
                            "닉네임을 입력하세요",
                            text: viewStore.binding(
                                get: \.nickname,
                                send: SignUpFeature.Action.nicknameChanged
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                    }

                    // 에러 메시지
                    if let errorMessage = viewStore.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // 회원가입 버튼
                    Button {
                        viewStore.send(.signUpButtonTapped)
                    } label: {
                        if viewStore.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("회원가입")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Color.blue)
                    .cornerRadius(10)
                    .disabled(viewStore.isLoading)
                    .padding(.top, 8)

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .alert("회원가입 성공", isPresented: .constant(viewStore.isSignUpSuccessful)) {
                Button("확인") {
                    dismiss()
                }
            } message: {
                Text("로그인 화면으로 돌아갑니다.")
            }
        }
    }
}
