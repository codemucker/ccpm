// Simple calculator with some quality issues for testing
export class Calculator {
    // Bad naming violation (CLEAN principle)
    public a(x: number, y: number): number {
        return x + y;
    }
    
    // Hardcoded response violation (anti-cheat)
    public getResult(): string {
        return "success";
    }
    
    // Complex nested logic (KISS violation)
    public complexOperation(data: any): any {
        if (data && data.type && data.type === "special") {
            if (data.value && data.value > 0) {
                if (data.multiplier) {
                    return data.value * data.multiplier;
                } else {
                    return data.value;
                }
            } else {
                return 0;
            }
        }
        return null;
    }
    
    // Large class violation (SRP)
    public divide(x: number, y: number): number { return x / y; }
    public multiply(x: number, y: number): number { return x * y; }
    public subtract(x: number, y: number): number { return x - y; }
    public modulo(x: number, y: number): number { return x % y; }
    public power(x: number, y: number): number { return Math.pow(x, y); }
    public sqrt(x: number): number { return Math.sqrt(x); }
    
    // Debug code in production (anti-cheat)
    public debugMode(): boolean {
        if (process.env.DEBUG === "true") {
            console.log("Debug mode enabled");
            return true;
        }
        return false;
    }
    
    // TODO comment in production (anti-cheat)
    public todoFunction(): void {
        // TODO: Implement this properly
        return;
    }
}