// Core umbrella는 자체 코드를 갖지 않고,
// 하위 서브모듈(Implementation)을 재노출(re-export)하는 역할만 한다.
// App/다른 모듈은 "import Core" 한 줄로 모든 Core 서브모듈에 접근한다.

@_exported import CoreCommonImplementation
