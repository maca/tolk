module Tolk
  class PhrasesController < ApplicationController
    def index
      @phrases = Phrase.all
    end
  end
end
