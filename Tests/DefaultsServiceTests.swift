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
        service.set(person1, for: key)

        let person2 = service.value(for: key)
        XCTAssertEqual(person1, person2)
    }

    func testClears() {
        let person = Person(name: "Matteo", age: 27)
        service.set(person, for: key)
        service.clear()
        XCTAssertNil(service.value(for: key))
    }

    func testSupportsMultipleWrites() {
        let person1 = Person(name: "Matteo", age: 27)
        service.set(person1, for: key)

        let person2 = service.value(for: key)
        XCTAssertEqual(person1, person2)

        let person3 = Person(name: "Alma", age: 30)
        service.set(person3, for: key)

        let person4 = service.value(for: key)
        XCTAssertEqual(person3, person4)
    }

    func testSupportsWritingNil() {
        let person = Person(name: "Matteo", age: 27)
        service.set(person, for: key)
        service.set(nil, for: key)
        XCTAssertNil(service.value(for: key))
    }

    private var key: DefaultsService.Key<Person> {
        DefaultsService.Key<Person>(name: #function)
    }

    private struct Person: Codable, Equatable {
        let name: String, age: Int
    }
}
