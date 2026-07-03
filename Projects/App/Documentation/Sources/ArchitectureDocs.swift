//
//  ArchitectureDocs.swift
//  ArchitectureDocs
//
//  프로젝트 전역 DocC 카탈로그(Architecture.docc) 전용 호스트 타겟.
//  실행 코드는 없다.
//
//  레이어 umbrella 를 `@_exported` 로 재노출해 카탈로그의 심볼 링크
//  (``HomeFeature`` 등)가 이 모듈의 심볼 그래프 안에서 해석되게 한다.
//  AppFeature/AppView 는 App 앱 타겟 소속이라 framework 이 import 할 수 없어
//  편입 불가 — 카탈로그에선 일반 코드 표기(`AppFeature`)를 쓴다.
//

@_exported import Core
@_exported import Domain
@_exported import Feature
@_exported import Shared
