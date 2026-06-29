//
//  ArchitectureDocs.swift
//  ArchitectureDocs
//
//  프로젝트 전역 DocC 카탈로그(Architecture.docc) 전용 호스트 타겟.
//  실행 코드는 없다.
//
//  의존 모듈을 `@_exported` 로 재노출해 이 모듈의 심볼 그래프에 편입시킨다.
//  이렇게 해야 카탈로그의 ``AppFeature`` / ``HomeFeature`` 같은 심볼 링크가
//  한 문서 안에서 해석되고, 전 피처 API 가 한 곳에서 브라우징된다.
//

@_exported import DomainActivityInterface
@_exported import FeatureActivity
@_exported import AppFeature
@_exported import DesignSystemKit
@_exported import FeatureHome
@_exported import DomainProfileInterface
@_exported import FeatureProfile
@_exported import DomainUserInterface
@_exported import FeatureUsers
