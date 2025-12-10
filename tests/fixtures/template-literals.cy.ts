const suiteName = "Template Literal";
const testName = "template test";

describe(`Suite with ${suiteName}`, () => {
  it(`should handle ${testName}`, () => {
    expect(true).toBe(true);
  });

  describe(`Nested ${suiteName} suite`, () => {
    it(`should handle nested ${testName}`, () => {
      expect(1).toBe(1);
    });
  });
});