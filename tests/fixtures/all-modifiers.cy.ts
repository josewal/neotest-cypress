describe("All Modifiers Suite", () => {
  it("should work with basic it", () => {
    expect(true).toBe(true);
  });

  it.skip("should be skipped", () => {
    expect(true).toBe(true);
  });

  it.only("should be focused", () => {
    expect(true).toBe(true);
  });

  describe.skip("should skip this suite", () => {
    it("should be in skipped suite", () => {
      expect(true).toBe(true);
    });
  });

  describe.only("should focus this suite", () => {
    it("should be in focused suite", () => {
      expect(true).toBe(true);
    });
  });

  describe("context tests", () => {
    it("should work with context", () => {
      expect(true).toBe(true);
    });

    context("nested context", () => {
      it("should work with nested context", () => {
        expect(true).toBe(true);
      });
    });

    context.skip("skipped context", () => {
      it("should be in skipped context", () => {
        expect(true).toBe(true);
      });
    });

    context.only("focused context", () => {
      it("should be in focused context", () => {
        expect(true).toBe(true);
      });
    });
  });
});