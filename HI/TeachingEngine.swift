import Foundation

struct TeachStep: Identifiable {
    let id = UUID()
    let text: String
    let highlight: String?

    init(_ text: String, highlight: String? = nil) {
        self.text = text
        self.highlight = highlight
    }
}

struct TeachExplanation {
    let heading: String
    let restatedQuestion: String
    let steps: [TeachStep]
    let finalLine: String
}

enum TeachingEngine {

    static func explain(for question: QuizQuestion) -> TeachExplanation {
        let raw = question.question
        let answer = question.correct_answer

        if let e = explainAddition(raw, answer: answer) { return e }
        if let e = explainMultiplication(raw, answer: answer) { return e }
        if let e = explainLinearEquation(raw, answer: answer) { return e }
        if let e = explainSolveForX(raw, answer: answer) { return e }
        if let e = explainQuadratic(raw, answer: answer) { return e }

        return TeachExplanation(
            heading: "Let's look at it together",
            restatedQuestion: "\(raw) = ?",
            steps: [TeachStep("The answer is \(answer).", highlight: answer)],
            finalLine: "\(raw) = \(answer)"
        )
    }

    private static func explainAddition(_ raw: String, answer: String) -> TeachExplanation? {
        guard let (a, b) = twoIntsSeparatedBy(raw, ops: ["+"]) else { return nil }
        let sum = a + b

        var steps: [TeachStep] = []
        steps.append(TeachStep("Start with \(a).", highlight: "\(a)"))

        if b <= 10 {
            let counted = (1...b).map { "\(a + $0)" }.joined(separator: ", ")
            steps.append(TeachStep("Count up \(b) more: \(counted).", highlight: "\(sum)"))
        } else {
            let aTens = (a / 10) * 10, aOnes = a % 10
            let bTens = (b / 10) * 10, bOnes = b % 10
            steps.append(TeachStep("Add the ones: \(aOnes) + \(bOnes) = \(aOnes + bOnes).", highlight: "\(aOnes + bOnes)"))
            steps.append(TeachStep("Add the tens: \(aTens) + \(bTens) = \(aTens + bTens).", highlight: "\(aTens + bTens)"))
            steps.append(TeachStep("Put them together: \(aTens + bTens) + \(aOnes + bOnes) = \(sum).", highlight: "\(sum)"))
        }
        steps.append(TeachStep("So \(a) + \(b) = \(sum).", highlight: "\(sum)"))

        return TeachExplanation(
            heading: "Let's add it up",
            restatedQuestion: "\(a) + \(b) = ?",
            steps: steps,
            finalLine: "\(a) + \(b) = \(sum)"
        )
    }

    private static func explainMultiplication(_ raw: String, answer: String) -> TeachExplanation? {
        guard let (a, b) = twoIntsSeparatedBy(raw, ops: ["x", "X", "×", "*"]) else { return nil }
        let product = a * b

        var steps: [TeachStep] = []
        steps.append(TeachStep("\(a) × \(b) means \(a) groups of \(b).", highlight: "\(a) groups"))

        let smaller = min(a, b)
        let larger = max(a, b)

        if smaller <= 6 {
            let terms = Array(repeating: "\(larger)", count: smaller).joined(separator: " + ")
            steps.append(TeachStep("Add \(larger), \(smaller) times: \(terms) = \(product).", highlight: "\(product)"))
        } else {
            let tensPart = (larger / 10) * 10
            let remainder = larger - tensPart
            if tensPart > 0 && remainder > 0 {
                steps.append(TeachStep(
                    "Split \(larger) into \(tensPart) + \(remainder).",
                    highlight: "\(tensPart) + \(remainder)"
                ))
                steps.append(TeachStep(
                    "(\(smaller) × \(tensPart)) + (\(smaller) × \(remainder)) = \(smaller * tensPart) + \(smaller * remainder) = \(product).",
                    highlight: "\(product)"
                ))
            } else {
                steps.append(TeachStep("\(a) × \(b) = \(product).", highlight: "\(product)"))
            }
        }
        steps.append(TeachStep("So \(a) × \(b) = \(product).", highlight: "\(product)"))

        return TeachExplanation(
            heading: "Let's multiply it out",
            restatedQuestion: "\(a) × \(b) = ?",
            steps: steps,
            finalLine: "\(a) × \(b) = \(product)"
        )
    }

    private static func explainLinearEquation(_ raw: String, answer: String) -> TeachExplanation? {
        guard let regex = try? NSRegularExpression(pattern: #"^(-?\d+)x\s*\+\s*(-?\d+)\s*=\s*(-?\d+)$"#) else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        guard let m = regex.firstMatch(in: trimmed, range: range),
              let a = intGroup(m, 1, in: trimmed),
              let b = intGroup(m, 2, in: trimmed),
              let c = intGroup(m, 3, in: trimmed),
              a != 0 else { return nil }

        let afterSubtract = c - b
        let x = afterSubtract / a

        let step2Text: String
        if b >= 0 {
            step2Text = "Subtract \(b) from both sides: \(a)x = \(afterSubtract)."
        } else {
            step2Text = "Add \(abs(b)) to both sides: \(a)x = \(afterSubtract)."
        }

        let step3Text: String
        if a > 0 {
            step3Text = "Divide both sides by \(a): x = \(afterSubtract) ÷ \(a) = \(x)."
        } else {
            step3Text = "Divide both sides by \(a): x = \(afterSubtract) ÷ (\(a)) = \(x)."
        }

        let steps: [TeachStep] = [
            TeachStep("We start with \(a)x + \(b) = \(c).", highlight: "\(a)x + \(b) = \(c)"),
            TeachStep(step2Text, highlight: "\(afterSubtract)"),
            TeachStep(step3Text, highlight: "\(x)")
        ]

        return TeachExplanation(
            heading: "Let's solve for x",
            restatedQuestion: "\(a)x + \(b) = \(c)",
            steps: steps,
            finalLine: "x = \(x)"
        )
    }

    private static func explainSolveForX(_ raw: String, answer: String) -> TeachExplanation? {
        guard let regex = try? NSRegularExpression(pattern: #"^(-?\d+)x\s*=\s*(-?\d+)$"#) else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        guard let m = regex.firstMatch(in: trimmed, range: range),
              let coefficient = intGroup(m, 1, in: trimmed),
              let result = intGroup(m, 2, in: trimmed),
              coefficient != 0 else { return nil }

        let x = result / coefficient

        let steps: [TeachStep] = [
            TeachStep("We start with \(coefficient)x = \(result).", highlight: "\(coefficient)x = \(result)"),
            TeachStep("Divide both sides by \(coefficient): x = \(result) ÷ \(coefficient) = \(x).", highlight: "\(x)")
        ]

        return TeachExplanation(
            heading: "Let's solve for x",
            restatedQuestion: "\(coefficient)x = \(result)",
            steps: steps,
            finalLine: "x = \(x)"
        )
    }

    private static func explainQuadratic(_ raw: String, answer: String) -> TeachExplanation? {
        guard let regex = try? NSRegularExpression(pattern: #"x\^2 \+ (-?\d+)x \+ (-?\d+) = 0"#) else { return nil }
        let range = NSRange(raw.startIndex..., in: raw)
        guard let m = regex.firstMatch(in: raw, range: range),
              let b = intGroup(m, 1, in: raw),
              let c = intGroup(m, 2, in: raw) else { return nil }

        let discriminant = b * b - 4 * c
        guard discriminant >= 0 else { return nil }
        let sqrtDisc = Int(Double(discriminant).squareRoot().rounded())
        guard sqrtDisc * sqrtDisc == discriminant else { return nil }

        let root1 = (-b + sqrtDisc) / 2
        let root2 = (-b - sqrtDisc) / 2
        let positiveRoot = max(root1, root2)

        let steps: [TeachStep] = [
            TeachStep("We need two numbers that multiply to \(c) and add to \(b).", highlight: "\(c)"),
            TeachStep("Those numbers are \(root1) and \(root2) — check: \(root1) + \(root2) = \(root1 + root2), \(root1) × \(root2) = \(root1 * root2).", highlight: "\(root1), \(root2)"),
            TeachStep("So the equation factors as (x - \(root1))(x - \(root2)) = 0.", highlight: "(x - \(root1))(x - \(root2))"),
            TeachStep("The roots are x = \(root1) and x = \(root2). The positive one is \(positiveRoot).", highlight: "\(positiveRoot)")
        ]

        return TeachExplanation(
            heading: "Let's factor it",
            restatedQuestion: "x² + \(b)x + \(c) = 0",
            steps: steps,
            finalLine: "x = \(positiveRoot)"
        )
    }

    private static func twoIntsSeparatedBy(_ raw: String, ops: [String]) -> (Int, Int)? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        for op in ops {
            let parts = trimmed.components(separatedBy: " \(op) ")
            if parts.count == 2, let a = Int(parts[0].trimmingCharacters(in: .whitespaces)),
               let b = Int(parts[1].trimmingCharacters(in: .whitespaces)) {
                return (a, b)
            }
        }
        return nil
    }

    private static func intGroup(_ match: NSTextCheckingResult, _ index: Int, in source: String) -> Int? {
        guard let range = Range(match.range(at: index), in: source) else { return nil }
        return Int(source[range])
    }
}
