@testable
import Fosdem
import XCTest

final class DefaultsServiceTests: XCTestCase {
    private var service = DefaultsService()

    override func setUp() {
        super.setUp()
        service = DefaultsService()
    }

    override func tearDown() {
        super.tearDown()
        service.clear()
    }

    func testWritesAndReads() {
        let person1 = Person(name: "Matteo", age: 27)
        XCTAssertNoThrow(try service.set(person1, for: .person))

        var person2: Person?
        XCTAssertNoThrow(try { person2 = try service.value(for: .person) }())
        XCTAssertEqual(person1, person2)
    }

    func testClears() {
        let person = Person(name: "Matteo", age: 27)
        XCTAssertNoThrow(try service.set(person, for: .person))

        service.clear()
        XCTAssertNil(try service.value(for: .person))
    }

    func testSupportsMultipleWrites() {
        let person1 = Person(name: "Matteo", age: 27)
        XCTAssertNoThrow(try service.set(person1, for: .person))

        var person2: Person?
        XCTAssertNoThrow(try { person2 = try service.value(for: .person) }())
        XCTAssertEqual(person1, person2)

        let person3 = Person(name: "Alma", age: 30)
        XCTAssertNoThrow(try service.set(person3, for: .person))

        var person4: Person?
        XCTAssertNoThrow(try { person4 = try service.value(for: .person) }())
        XCTAssertEqual(person3, person4)
    }

    func testSupportsWritingNil() {
        let person1 = Person(name: "Matteo", age: 27)
        XCTAssertNoThrow(try service.set(person1, for: .person))
        XCTAssertNoThrow(try service.set(nil, for: .person))

        var person2: Person?
        XCTAssertNoThrow(try { person2 = try service.value(for: .person) }())
        XCTAssertNil(person2)
    }

    func testReportsEncodingFailures() {
        let thrower = EncodeThrower()
        let throwerKey = DefaultsService.Key<EncodeThrower>(name: #function)
        XCTAssertThrowsError(try service.set(thrower, for: throwerKey))
    }

    func testReportsDecodingFailures() {
        let thrower = DecodeThrower()
        let throwerKey = DefaultsService.Key<DecodeThrower>(name: #function)
        XCTAssertNoThrow(try service.set(thrower, for: throwerKey))
        XCTAssertThrowsError(try service.value(for: throwerKey))
    }

    fileprivate struct Person: Codable, Equatable {
        let name: String, age: Int
    }

    fileprivate struct DecodeThrower: Codable {
        init() {}

        init(from _: Decoder) throws {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "test"))
        }
    }

    fileprivate struct EncodeThrower: Codable {
        func encode(to _: Encoder) throws {
            throw EncodingError.invalidValue(Void(), EncodingError.Context(codingPath: [], debugDescription: "test"))
        }
    }
}

private extension DefaultsService.Key {
    static var person: DefaultsService.Key<DefaultsServiceTests.Person> {
        DefaultsService.Key<DefaultsServiceTests.Person>(name: #function)
    }
}
