# lat.md 검색 + 프로젝트 생성 단축 명령
# 사용: make lat q=profile   /   make lat-all   /   make lat-deps q=profile
#
# 검색은 ripgrep(rg) 이 있으면 rg, 없으면 grep 으로 자동 폴백.
# 속도를 위해 ripgrep 설치 권장: brew install ripgrep

RG := $(shell command -v rg 2>/dev/null)
ifeq ($(RG),)
  SEARCH = grep -rn --include='*.swift'
else
  SEARCH = rg --type swift -n
endif

.PHONY: lat lat-all lat-deps lint lint-fix generate test scaffold-feature scaffold-domain scaffold-core scaffold-shared

# 특정 도메인과 엮인 코드 전부 (위키링크 [[도메인 으로 검색 → delegate 의존도 잡힘)
lat:
	@$(SEARCH) '\[\[$(q)' Projects 2>/dev/null || echo "no @lat link to '$(q)'"

# 코드 전체의 @lat 라벨 목록
lat-all:
	@$(SEARCH) '@lat:' Projects 2>/dev/null

# 이 도메인을 depends-on 하는 코드 (= 바꾸면 영향받는 곳)
lat-deps:
	@$(SEARCH) 'depends-on.*$(q)' Projects 2>/dev/null || echo "nothing depends on '$(q)'"

# SwiftLint — 전 모듈 린트 (CI·터미널용. 빌드 페이즈와 같은 .swiftlint.yml 사용)
lint:
	@swiftlint lint --quiet

# 자동 수정 가능한 것 고치고 다시 린트
lint-fix:
	@swiftlint --fix && swiftlint lint --quiet

# Tuist 프로젝트 생성
generate:
	@tuist install && tuist generate

# 새 Feature 모듈 scaffold (예: make scaffold-feature name=Home)
# 파일 헤더의 author 는 git config user.name 에서 자동으로 채운다 (Tuist 매니페스트 실행 환경은
# Process/ProcessInfo.environment 를 못 읽어 stencil 기본값으로는 불가 — 그래서 여기서 셸로 주입).
# 생성 후 Project.swift 상단 ⚠️ 주석의 수동 작업 2단계를 완료하고 make generate 실행
scaffold-feature:
	@[ -n "$(name)" ] || (echo "❌ name 필수. 예: make scaffold-feature name=Home"; exit 1)
	@tuist scaffold Feature --name $(name) --author "$$(git config user.name)"
	@echo "✅ Feature$(name) 생성 완료. Projects/Feature/Feature$(name)/Project.swift 의 ⚠️ 주석을 확인하세요."

# 새 Domain 모듈 scaffold (예: make scaffold-domain name=User)
# 생성 후 Project.swift 상단 ⚠️ 주석의 수동 작업 2단계를 완료하고 make generate 실행
scaffold-domain:
	@[ -n "$(name)" ] || (echo "❌ name 필수. 예: make scaffold-domain name=User"; exit 1)
	@tuist scaffold Domain --name $(name) --author "$$(git config user.name)"
	@echo "✅ Domain$(name) 생성 완료. Projects/Domain/Domain$(name)/Project.swift 의 ⚠️ 주석을 확인하세요."

# 새 Core 모듈 scaffold (예: make scaffold-core name=Network)
# 생성 후 Project.swift 상단 ⚠️ 주석의 수동 작업 2단계를 완료하고 make generate 실행
scaffold-core:
	@[ -n "$(name)" ] || (echo "❌ name 필수. 예: make scaffold-core name=Network"; exit 1)
	@tuist scaffold Core --name $(name) --author "$$(git config user.name)"
	@echo "✅ Core$(name) 생성 완료. Projects/Core/Core$(name)/Project.swift 의 ⚠️ 주석을 확인하세요."

# 새 Shared 모듈 scaffold (예: make scaffold-shared name=DesignSystem)
# 생성 후 Project.swift 상단 ⚠️ 주석의 수동 작업 2단계를 완료하고 make generate 실행
scaffold-shared:
	@[ -n "$(name)" ] || (echo "❌ name 필수. 예: make scaffold-shared name=DesignSystem"; exit 1)
	@tuist scaffold Shared --name $(name) --author "$$(git config user.name)"
	@echo "✅ Shared$(name) 생성 완료. Projects/Shared/Shared$(name)/Project.swift 의 ⚠️ 주석을 확인하세요."

# Feature 테스트 (예: make test scheme=FeatureHome [device='iPhone 15'])
#
# 기기 이름이 여러 OS 런타임에 중복되면(예: iPhone 16 이 18.0·26.1 둘 다 존재)
# xcodebuild 가 name 만으론 못 골라 "Unable to find a device" 로 죽는다.
# → 사용 가능한 시뮬레이터 UDID 로 해석해서 넘긴다. device= 로 기기 변경 가능.
device ?= iPhone 16
test:
	@id=$$(xcrun simctl list devices available | grep -E '^ +$(device) \(' | grep -oE '[0-9A-Fa-f-]{36}' | head -1); \
	if [ -z "$$id" ]; then echo "❌ '$(device)' 시뮬레이터 없음. 사용 가능:"; xcrun simctl list devices available | grep -E '^ +iPhone'; exit 1; fi; \
	xcodebuild -workspace App.xcworkspace -scheme $(scheme) -destination "platform=iOS Simulator,id=$$id" test
