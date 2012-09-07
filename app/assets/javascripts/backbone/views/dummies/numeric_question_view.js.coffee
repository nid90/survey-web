##= require ./question_view
SurveyBuilder.Views.Dummies ||= {}

# Represents a dummy single line question on the DOM
class SurveyBuilder.Views.Dummies.NumericQuestionView extends SurveyBuilder.Views.Dummies.QuestionView

  events:
    "click": 'show_actual'

  render: ->
    template = $('#dummy_numeric_question_template').html()
    super template