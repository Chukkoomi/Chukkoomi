//
//  LoginRootView.swift
//  Chukkoomi
//
//  Created by 서지민 on 11/7/25.
//

import SwiftUI
import ComposableArchitecture

struct LoginRootView: View {

    let loginStore = Store(initialState: LoginFeature.State()) {
        LoginFeature()
    }

    let signUpStore = Store(initialState: SignUpFeature.State()) {
        SignUpFeature()
    }

    let logStore = Store(initialState: LogFeature.State()) {
        LogFeature()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 로고 또는 타이틀
                Text("로그인")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 60)

                Spacer()

                // 로그인 폼
                WithViewStore(loginStore, observe: { $0 }) { viewStore in
                    VStack(spacing: 16) {
                        // 이메일 입력 필드
                        VStack(alignment: .leading, spacing: 8) {
                            Text("이메일")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            TextField(
                                "이메일을 입력하세요",
                                text: viewStore.binding(
                                    get: \.email,
                                    send: LoginFeature.Action.emailChanged
                                )
                            )
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                        }

                        // 비밀번호 입력 필드
                        VStack(alignment: .leading, spacing: 8) {
                            Text("비밀번호")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            SecureField(
                                "비밀번호를 입력하세요",
                                text: viewStore.binding(
                                    get: \.password,
                                    send: LoginFeature.Action.passwordChanged
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

                        // 로그인 버튼
                        Button {
                            viewStore.send(.loginButtonTapped)
                        } label: {
                            if viewStore.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Text("로그인")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .background(Color.blue)
                        .cornerRadius(10)
                        .disabled(viewStore.isLoading)

                        // 회원가입 버튼
                        NavigationLink {
                            SignUpView(store: signUpStore)
                        } label: {
                            Text("회원가입")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 8)

                        // 서버 로그 조회 버튼
                        NavigationLink {
                            LogView(store: logStore)
                        } label: {
                            Text("서버 로그 조회")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 4)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}
