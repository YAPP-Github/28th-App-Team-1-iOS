//
//  Source.swift
//  SharedDesignSystemImplementation
//
//  Created by EunseoKim on 26/07/18.
//

// 디자인 토큰은 상수 계약이라 live 구현이 따로 없다 — 전부 Interface 에 산다.
// App 이 umbrella(Shared)만 link 해도 토큰이 보이도록 Interface 를 재노출한다.
@_exported import SharedDesignSystemInterface
