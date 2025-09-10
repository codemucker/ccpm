// Test file with quality issues
import { Calculator } from './calculator';

describe('Calculator', () => {
    const calc = new Calculator();
    
    // Bad test name (MEANINGFUL violation)
    it('test1', () => {
        expect(calc.a(2, 3)).toBe(5);
    });
    
    // Weak assertion (FIRST violation) 
    it('should work', () => {
        expect(true).toBe(true);
    });
    
    // No proper test structure (GIVEN-WHEN-THEN violation)
    it('complex test', () => {
        const result = calc.complexOperation({type: "special", value: 10, multiplier: 2});
        expect(result).toBe(20);
    });
    
    // Good test for comparison
    it('should add two numbers correctly', () => {
        // Given
        const firstNumber = 5;
        const secondNumber = 3;
        
        // When
        const result = calc.a(firstNumber, secondNumber);
        
        // Then
        expect(result).toBe(8);
    });
});