import { PonyracerPage } from './app.po';

describe('ponyracer App', () => {
  let page: PonyracerPage;

  beforeEach(() => {
    page = new PonyracerPage();
  });

  it('should display welcome message', done => {
    page.navigateTo();
    page.getParagraphText()
      .then(msg => expect(msg).toEqual('Welcome to app!!'))
      .then(done, done.fail);
  });
});
