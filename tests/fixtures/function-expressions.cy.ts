describe("Function Expression Suite", function() {
  it("should use function expressions", function() {
    expect(true).toBe(true);
  });

  it("should handle function expressions with template literals", function() {
    expect(1).toBe(1);
  });

  describe("Nested Function Suite", function() {
    it("should handle nested function expressions", function() {
      expect(2).toBe(2);
    });
  });
});