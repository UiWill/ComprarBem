// Mock for jsPDF

export const jsPDF = jest.fn().mockImplementation((orientation, unit, format) => ({
  setFont: jest.fn().mockReturnThis(),
  setFontSize: jest.fn().mockReturnThis(),
  text: jest.fn().mockReturnThis(),
  line: jest.fn().mockReturnThis(),
  getTextWidth: jest.fn().mockReturnValue(50),
  save: jest.fn().mockReturnThis(),
  addPage: jest.fn().mockReturnThis(),
  setTextColor: jest.fn().mockReturnThis(),
  setDrawColor: jest.fn().mockReturnThis(),
  setFillColor: jest.fn().mockReturnThis(),
  rect: jest.fn().mockReturnThis(),
  circle: jest.fn().mockReturnThis(),
  ellipse: jest.fn().mockReturnThis(),
  triangle: jest.fn().mockReturnThis(),
  roundedRect: jest.fn().mockReturnThis(),
  setLineDashPattern: jest.fn().mockReturnThis(),
  setLineWidth: jest.fn().mockReturnThis(),
  setLineCap: jest.fn().mockReturnThis(),
  setLineJoin: jest.fn().mockReturnThis(),
}))