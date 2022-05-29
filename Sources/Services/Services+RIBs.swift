
protocol HasAgendaBuilder {
  var agendaBuilder: AgendaBuildable { get }
}

extension Services: HasAgendaBuilder {
  var agendaBuilder: AgendaBuildable {
    AgendaBuilder(dependency: self)
  }
}

protocol HasEventBuilder {
  var eventBuilder: EventBuildable { get }
}

extension Services: HasEventBuilder {
  var eventBuilder: EventBuildable {
    EventBuilder(dependency: self)
  }
}

protocol HasMapBuilder {
  var mapBuilder: MapBuildable { get }
}

extension Services: HasMapBuilder {
  var mapBuilder: MapBuildable {
    MapBuilder(dependency: self)
  }
}

protocol HasMoreBuilder {
  var moreBuilder: MoreBuildable { get }
}

extension Services: HasMoreBuilder {
  var moreBuilder: MoreBuildable {
    MoreBuilder(dependency: self)
  }
}

protocol HasScheduleBuilder {
  var scheduleBuilder: ScheduleBuildable { get }
}

extension Services: HasScheduleBuilder {
  var scheduleBuilder: ScheduleBuildable {
    ScheduleBuilder(dependency: self)
  }
}

protocol HasSearchBuilder {
  var searchBuilder: SearchBuildable { get }
}

extension Services: HasSearchBuilder {
  var searchBuilder: SearchBuildable {
    SearchBuilder(dependency: self)
  }
}

protocol HasVideosBuilder {
  var videosBuilder: VideosBuildable { get }
}

extension Services: HasVideosBuilder {
  var videosBuilder: VideosBuildable {
    VideosBuilder(dependency: self)
  }
}

protocol HasYearBuilder {
  var yearBuilder: YearBuildable { get }
}

extension Services: HasYearBuilder {
  var yearBuilder: YearBuildable {
    YearBuilder(dependency: self)
  }
}

protocol HasYearsBuilder {
  var yearsBuilder: YearsBuildable { get }
}

extension Services: HasYearsBuilder {
  var yearsBuilder: YearsBuildable {
    YearsBuilder(dependency: self)
  }
}
