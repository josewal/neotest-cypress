describe("Async Tests Suite", async () => {
  it("should handle async arrow functions", async () => {
    await new Promise(resolve => setTimeout(resolve, 1));
  });

  it("should handle async tests", async () => {
    const result = await Promise.resolve("test");
    expect(result).toBe("test");
  });

  describe("Nested Async Suite", function() {
    it("should handle nested async functions", async () => {
      const data = await Promise.resolve({ value: 42 });
      expect(data.value).toBe(42);
    });
  });
});