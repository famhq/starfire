_reduce = require 'lodash/reduce'
_defaultsDeep = require 'lodash/defaultsDeep'
Rx = require 'rx-lite'
moment = require 'moment'

config = require '../config'

# missing: card_info, channel picker, edit group, edit group change badge
# events 'participants', 'begins', 'ends'
# group list 'members'
# thread points
# friendspage
# profile page share

languages =
  en: require '../lang/en/strings_en'
  es: require '../lang/es/strings_es'
  it: require '../lang/it/strings_it'
  fr: require '../lang/fr/strings_fr'
  zh: require '../lang/zh/strings_zh'
  ja: require '../lang/ja/strings_ja'
  ko: require '../lang/ko/strings_ko'
  de: require '../lang/de/strings_de'
  pt: require '../lang/pt/strings_pt'
  pl: require '../lang/pl/strings_pl'

class Language
  constructor: ({language}) ->
    @language = new Rx.BehaviorSubject language
    @setLanguage language

  setLanguage: (language) =>
    @language.onNext language
    moment.locale language

    # change from 'a few seconds ago'
    justNowStr = @get 'time.justNow'

    moment.fn.fromNowModified = (a) ->
      if Math.abs(moment().diff(this)) < 30000
        # 1000 milliseconds
        return justNowStr
      @fromNow a

  getLanguage: => @language

  getLanguageStr: => @language.getValue()

  get: (strKey, replacements) =>
    language = @language.getValue()
    baseResponse = languages[language]?[strKey] or
                    languages['en']?[strKey] or ''

    unless baseResponse
      console.log 'missing', strKey

    if typeof baseResponse is 'object'
      # some languages (czech) have many plural forms
      pluralityCount = replacements[baseResponse.pluralityCheck]
      baseResponse = baseResponse.plurality[pluralityCount] or
                      baseResponse.plurality.other or ''

    _reduce replacements, (str, replace, key) ->
      find = ///{#{key}}///g
      str.replace find, replace
    , baseResponse


module.exports = Language
