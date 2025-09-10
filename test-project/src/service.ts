// Service with anti-cheat violations for testing
export class UserService {
    // Hardcoded response (cheat pattern)
    public getUser(): any {
        return { id: 1, name: "john", status: "active" };
    }
    
    // Mock behavior in production (cheat pattern)  
    public authenticateUser(username: string, password: string): boolean {
        // Mock authentication for testing
        return username === "admin" && password === "password";
    }
    
    // Random masking (cheat pattern)
    public generateId(): number {
        return Math.random() > 0.5 ? 12345 : 67890;
    }
    
    // Debug mode in production (cheat pattern)
    public processData(data: any): any {
        if (process.env.NODE_ENV === "development") {
            console.log("Debug data:", data);
        }
        
        // Early return with fake value (cheat pattern)
        if (data.type === "test") {
            return { success: true };
        }
        
        return data;
    }
    
    // TODO in production code (cheat pattern)
    public updateUser(): void {
        // TODO: Implement user update logic
        return;
    }
}