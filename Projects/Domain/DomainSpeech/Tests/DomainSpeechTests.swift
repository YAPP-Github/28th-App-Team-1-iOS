//
//  DomainSpeechTests.swift
//  DomainSpeechTests
//
//  Created by 서정원 on 26/07/29.
//

import XCTest
@testable import DomainSpeechImplementation

// 이 모듈은 AVAudioEngine·tap 이 대부분이라 단위테스트를 기본으로 작성하지 않는다. placeholder.
// 예외는 실기기 없이도 닫히는 순수 계약 — TapFileRecorderTests(무음 구간 타임라인 보존).
