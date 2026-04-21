#!/usr/bin/env -S node --import=tsx

import birds from './master.json' with { type: "json" }
import { writeFileSync } from 'node:fs'

// Shorthand constructor unavailable in tsx
class Bird {
    constructor(name: string, points: number) {
        this.name = name
        this.points = points
    }
}

const expansions = new Set([
    "core",
    "european",
    "oceania",
    "asia",
    "americas",
])

const expansionData = new Map<string, Bird[]>(expansions.entries().map(([e]) => [e, []]))

for (const birdData of birds) {
    const expansion = birdData.Set
    if (expansions.has(expansion)) {
        const bird = new Bird(
            birdData["Common name"],
            birdData["Victory points"],
        )
        expansionData.get(expansion)!.push(bird)
    }
}

for (const [expansion, data] of expansionData) {
    const json = JSON.stringify(data)
    writeFileSync(`${expansion}.json`, json)
}