//
//  Calculator.swift
//  calculator
//
//  Created by Илья Лошкарёв on 21.09.17.
//  Copyright © 2017 Илья Лошкарёв. All rights reserved.
//

import Foundation


/// Доступные операции
public enum UnaryOperation: String {
    case sign = "±",
    perc = "%"
}

public enum BinaryOperation: String {
    case add = "+",
    sub = "-",
    mul = "×",
    div = "÷"
}


/// Протокол калькулятора
public protocol Calculator {
    var delegate: CalculatorDelegate? { get set }
    var inputLength: UInt { get }
    
    func addChar(_ c: String)
    func applyOperation(_ op: UnaryOperation)
    func applyOperation(_ op: BinaryOperation)
    func compute()
    func clear()
}

class CalculatorImpl : Calculator {    
    var delegate: CalculatorDelegate?
    var inputLength: UInt
    var lastNumber: Double
    var lastOperation: BinaryOperation
    var opWasExecuted: Bool
    var currentString: String
    
    init(inputLength len: UInt) {
        inputLength = len
        lastNumber = 0
        lastOperation = BinaryOperation.add
        opWasExecuted = false
        currentString = "0"
    }
    
    func addChar(_ c: String) {
        if currentString == "0" {
            currentString = ""
        }
        
        if opWasExecuted {
            currentString = ""
            opWasExecuted = false
        }
        
        if currentString == "" && c == "." {
            currentString = "0"
        }
        
        if isOverflow(currentString + c) {
            delegate?.calculatorDidInputOverflow(self)
            return
        }
        currentString += c
        delegate?.calculatorDidUpdateValue(self, with: currentString)
    }
    
    func applyOperation(_ op: UnaryOperation) {
        var value = Double(currentString) ?? 0
        switch op {
        case UnaryOperation.perc:
            value /= 100
        case UnaryOperation.sign:
            value *= -1
        }
        var newValue = valueToString(value)
        if isOverflow(newValue) && !tryFix(&newValue) {
            clear()
            delegate?.calculatorDidInputOverflow(self)
            return
        }
        currentString = newValue
        delegate?.calculatorDidUpdateValue(self, with: currentString)
    }
    
    func applyOperation(_ op: BinaryOperation) {
        execLastOp()
        lastOperation = op
    }
    
    func compute() {
        execLastOp()
        lastNumber = 0
        lastOperation = BinaryOperation.add
    }
    
    func clear() {
        currentString = "0"
        lastNumber = 0
        lastOperation = BinaryOperation.add
        delegate?.calculatorDidUpdateValue(self, with: currentString)
    }
    
    func execLastOp() {
        let value = Double(currentString) ?? 0
        var lastNumberTemp = lastNumber
        
        switch lastOperation {
        case BinaryOperation.add:
            lastNumberTemp += value
        case BinaryOperation.sub:
            lastNumberTemp -= value
        case BinaryOperation.mul:
            lastNumberTemp *= value
        case BinaryOperation.div:
            if value == 0 {
                clear()
                delegate?.calculatorDidNotCompute(self, withError: "Cannot divide by zero")
                return
            }
            lastNumberTemp /= value
        }
        
        var newValue = valueToString(lastNumberTemp)
        if isOverflow(newValue) && !tryFix(&newValue) {
            clear()
            delegate?.calculatorDidInputOverflow(self)
            return
        }
        
        lastNumber = lastNumberTemp
        currentString = newValue
        delegate?.calculatorDidUpdateValue(self, with: currentString)
        opWasExecuted = true
    }
    
    func valueToString(_ value: Double) -> String {
        if (value - floor(value) == 0) {
            return String(Int(value))
        } else {
            return String(value)
        }
    }
    
    func isOverflow(_ value: String) -> Bool {
        return value.count > inputLength
    }
    
    func tryFix(_ value: inout String) -> Bool {
        let doubleValue = Double(value) ?? 0
        let mainPart = String(Int(floor(doubleValue)))
        if mainPart.count > (inputLength - 2) {
            return false
        }
        value = String(format: "%.\(Int(inputLength) - mainPart.count - 1)f", doubleValue)
        value = valueToString(Double(value) ?? 0) // to avoid of redundant zeros at the end
        return true
    }
}
