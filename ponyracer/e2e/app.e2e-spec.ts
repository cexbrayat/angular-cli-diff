import { PonyracerPage } from './app.po';

describe('ponyracer App', () => {
  let page: PonyracerPage;

  beforeEach(() => {
    page = new PonyracerPage();
  });

  it('should display welcome message', () => {
    page.navigateTo();
    expect(page.getParagraphText()).toEqual('Welcome to app!!');
  });
});
