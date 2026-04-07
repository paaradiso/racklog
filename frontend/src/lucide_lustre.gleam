import lustre/attribute.{type Attribute, attribute}
import lustre/element/svg

pub fn trash_2(attributes: List(Attribute(a))) {
  svg.svg(
    [
      attribute("stroke-linejoin", "round"),
      attribute("stroke-linecap", "round"),
      attribute("stroke-width", "2"),
      attribute("stroke", "currentColor"),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 24 24"),
      attribute("height", "24"),
      attribute("width", "24"),
      ..attributes
    ],
    [
      svg.path([attribute("d", "M10 11v6")]),
      svg.path([attribute("d", "M14 11v6")]),
      svg.path([attribute("d", "M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6")]),
      svg.path([attribute("d", "M3 6h18")]),
      svg.path([attribute("d", "M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2")]),
    ],
  )
}

pub fn pencil(attributes: List(Attribute(a))) {
  svg.svg(
    [
      attribute("stroke-linejoin", "round"),
      attribute("stroke-linecap", "round"),
      attribute("stroke-width", "2"),
      attribute("stroke", "currentColor"),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 24 24"),
      attribute("height", "24"),
      attribute("width", "24"),
      ..attributes
    ],
    [
      svg.path([
        attribute(
          "d",
          "M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z",
        ),
      ]),
      svg.path([attribute("d", "m15 5 4 4")]),
    ],
  )
}
