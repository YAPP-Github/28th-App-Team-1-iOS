//
//  HomeFeatureInterface.swift
//  HomeFeatureInterface
//
//  Created by EunseoKim on 5/29/26.
//

import Foundation

// MARK: — 학습 노트
//
// TCA 의 `@Reducer` 매크로는 한 struct 안의 State / Action / body 를 함께 잡는다.
// 그 결과 외부 모듈이 HomeFeature 를 의존할 때 사실상 모든 public 심볼이 필요해
// "Interface 와 구현 분리" 의 본래 이득 (구현 변경 시 다른 모듈 재컴파일 차단)
// 이 크지 않다.
//
// MFA 의 Interface 분리가 진짜 빛나는 자리는 Client / Adapter — 예: UserClient 의
// 인터페이스만 노출하고 Live 구현은 별도 target. 이 골격은 학습용 placeholder 로
// 두고, 의미 있는 Interface 분리 사례는 추후 Data layer (UserClient 등) 에서 본다.

public enum HomeFeaturePackageInfo {
    public static let identifier = "HomeFeatureInterface"
}
