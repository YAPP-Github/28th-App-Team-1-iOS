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

.PHONY: lat lat-all lat-deps generate test

# 특정 도메인과 엮인 코드 전부 (위키링크 [[도메인 으로 검색 → delegate 의존도 잡힘)
lat:
	@$(SEARCH) '\[\[$(q)' Projects 2>/dev/null || echo "no @lat link to '$(q)'"

# 코드 전체의 @lat 라벨 목록
lat-all:
	@$(SEARCH) '@lat:' Projects 2>/dev/null

# 이 도메인을 depends-on 하는 코드 (= 바꾸면 영향받는 곳)
lat-deps:
	@$(SEARCH) 'depends-on.*$(q)' Projects 2>/dev/null || echo "nothing depends on '$(q)'"

# Tuist 프로젝트 생성
generate:
	@tuist install && tuist generate

# Feature 테스트 (예: make test scheme=UsersFeature)
test:
	@xcodebuild -workspace Architecture.xcworkspace -scheme $(scheme) \
		-destination 'platform=iOS Simulator,name=iPhone 16' test
