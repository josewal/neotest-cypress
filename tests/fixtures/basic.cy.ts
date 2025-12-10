describe("basic test suite", () => {
  it("should pass", () => {
    expect(true).toBe(true);
  });

  describe("nested suite", () => {
    it("should also pass", () => {
      cy.visit("/");
    });
  });
});
