//
//  UserClientMock.swift
//  DomainUserTesting
//
//  Created by EunseoKim on 26/07/23.
//

import DomainUserInterface
import Foundation

public extension UserClient {
    /// 다른 모듈의 테스트에서 주입하는 mock — 등록 완료된 프로필과 무해한 성공을 돌려준다.
    static var mock: UserClient {
        UserClient(
            profile: {
                UserProfile(
                    name: "히릿",
                    jobRole: "BACKEND",
                    jobRoleLabel: "백엔드",
                    careerYears: 3,
                    remainingTicketCount: 2
                )
            },
            updateProfile: { _ in },
            registerName: { _ in },
            checkName: { _ in true }
        )
    }
}
