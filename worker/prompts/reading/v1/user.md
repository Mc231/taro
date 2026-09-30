<reading_language code="{{locale_code}}">{{locale_name}}</reading_language>
<style_notes>
{{style_notes}}
</style_notes>
<spread id="{{spread_id}}" name="{{spread_name}}" cards="{{card_count}}">
{{spread_note}}
</spread>
<length>
{{length_budget}}
</length>
<cards>
{{cards}}
</cards>
{{spread_facts}}<prefilter_hint>{{prefilter_hint}}</prefilter_hint>
<user_question>{{user_question}}</user_question>
{{regeneration_note}}
Classify first; if not "none", return only the refusal shape. Otherwise write this {{spread_name}} reading in {{locale_name}}. {{address}} {{question_focus}}
Before you reply, check:
- every string is in the reading language, with the names from <cards>;
- each section keeps its sentence count and range from <length>;
- each interpretation opens with its card and reads its orientation, position and one image detail;
- no rejected word in any form (watch for {{check_words}}) and no certainty, time or odds;
- nothing invented about the reader, no hinted yes or no, no ranking of options;
- every prompt is an open question with no unstated premise.
Return only the JSON object.
